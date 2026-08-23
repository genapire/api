#!/usr/bin/env bash
#
# git-batch-push.sh — batchowe commitowanie i wysyłanie dużej liczby zmian na GitHub.
#
# Główny problem, który rozwiązuje: GitHub odrzuca push, gdy pojedynczy pack
# jest zbyt duży (limit pack ~2 GB, pojedynczy plik 100 MB, timeout HTTP).
# Dlatego batche są ograniczane NIE tylko liczbą plików, ale przede wszystkim
# łącznym rozmiarem w bajtach, a push jest ponawiany i — w razie porażki —
# rozbijany na pojedyncze commity.
#
# Użycie:
#   ./git-batch-push.sh                  # tryb ciągły (daemon)
#   ./git-batch-push.sh --once           # jeden przebieg, bez czekania
#   ./git-batch-push.sh --dry-run        # pokaż co by zrobił
#   BRANCH=main BATCH_MB=200 ./git-batch-push.sh
#
set -uo pipefail

# ------------------------- Konfiguracja (env / flagi) -------------------------
BRANCH="${BRANCH:-master}"
REMOTE="${REMOTE:-origin}"
BATCH_SIZE="${BATCH_SIZE:-2000}"        # max plików w jednym commicie
BATCH_MB="${BATCH_MB:-256}"             # max MB w jednym commicie (kluczowe dla GitHuba)
MAX_FILE_MB="${MAX_FILE_MB:-95}"        # pliki większe są pomijane (GitHub odrzuca >100 MB)
MIN_FILES="${MIN_FILES:-1000}"          # minimalna liczba plików, by zrobić commit
WAIT_MINUTES="${WAIT_MINUTES:-10}"      # ile czekać, gdy zmian jest za mało
PUSH_RETRIES="${PUSH_RETRIES:-5}"       # liczba prób pusha
PUSH_RETRY_DELAY="${PUSH_RETRY_DELAY:-15}"  # bazowe opóźnienie (backoff wykładniczy)
COMMIT_MSG="${COMMIT_MSG:-Updated API data}"
GC_EVERY="${GC_EVERY:-20}"              # co ile commitów uruchomić `git gc --auto`
ONCE=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --once) ONCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --branch) BRANCH="$2"; shift ;;
    --remote) REMOTE="$2"; shift ;;
    --batch-size) BATCH_SIZE="$2"; shift ;;
    --batch-mb) BATCH_MB="$2"; shift ;;
    --min-files) MIN_FILES="$2"; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Nieznany argument: $1" >&2; exit 2 ;;
  esac
  shift
done

BATCH_BYTES=$(( BATCH_MB * 1024 * 1024 ))
MAX_FILE_BYTES=$(( MAX_FILE_MB * 1024 * 1024 ))

# ------------------------------- Pomocnicze ----------------------------------
log() { printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
die() { log "BŁĄD: $*"; exit 1; }

RUNNING=1
trap 'RUNNING=0; log "Otrzymano sygnał — kończę po bieżącym batchu..."' INT TERM

file_size() {
  # GNU (unraid/linux) z fallbackiem na BSD/macOS; brak pliku (usunięty) => 0
  stat -c %s -- "$1" 2>/dev/null || stat -f %z -- "$1" 2>/dev/null || echo 0
}

# --------------------------- Walidacja środowiska ----------------------------
git rev-parse --git-dir >/dev/null 2>&1 || die "To nie jest repozytorium git."
cd "$(git rev-parse --show-toplevel)" || die "Nie mogę wejść do katalogu głównego repo."

# Blokada — chroni przed równoległym uruchomieniem (np. z crona)
LOCK_FILE="$(git rev-parse --git-dir)/batch-push.lock"
exec 9>"$LOCK_FILE" || die "Nie mogę utworzyć locka."
if command -v flock >/dev/null 2>&1; then
  flock -n 9 || die "Inna instancja skryptu już działa ($LOCK_FILE)."
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[ "$CURRENT_BRANCH" = "$BRANCH" ] || die "Jesteś na '$CURRENT_BRANCH', a skrypt ma pushować '$BRANCH'."

git config --get user.email >/dev/null || die "Brak git user.email — ustaw przed uruchomieniem."

# --pathspec-from-file wymaga git >= 2.25
git_ver="$(git --version | awk '{print $3}')"
git_major="${git_ver%%.*}"; git_rest="${git_ver#*.}"; git_minor="${git_rest%%.*}"
if [ "$git_major" -lt 2 ] || { [ "$git_major" -eq 2 ] && [ "$git_minor" -lt 25 ]; }; then
  die "Wymagany git >= 2.25 (masz $git_ver)."
fi

# Ustawienia zmniejszające ryzyko odrzucenia/timeoutu przy dużych pushach
git config http.postBuffer 524288000     # 500 MB bufor HTTP
git config http.version HTTP/1.1         # HTTP/2 bywa źródłem RPC failed przy dużych pushach
git config pack.windowMemory 256m
git config pack.packSizeLimit 1g
git config core.compression 6

# --------------------------- Zbieranie plików --------------------------------
# -z => obsługa nazw ze spacjami/UTF-8; łączymy modified + deleted + untracked
pending_files_z() {
  git ls-files -z --modified --deleted --others --exclude-standard | sort -zu
}

pending_count() {
  pending_files_z | tr '\0' '\n' | grep -c . || true
}

# ------------------------------- Push logic ----------------------------------
push_single_commits() {
  # Awaryjnie: gdy zbiorczy push padnie (za duży pack), wysyłamy commit po commicie.
  local shas sha
  git fetch --quiet "$REMOTE" "$BRANCH" 2>/dev/null || true
  shas="$(git rev-list --reverse "${REMOTE}/${BRANCH}..HEAD" 2>/dev/null)" || return 1
  [ -n "$shas" ] || return 0
  log "Push zbiorczy nie przeszedł — wysyłam commit po commicie ($(echo "$shas" | wc -l))..."
  for sha in $shas; do
    log "  -> $sha"
    git push "$REMOTE" "${sha}:refs/heads/${BRANCH}" || return 1
  done
  return 0
}

do_push() {
  local attempt=1 delay="$PUSH_RETRY_DELAY"
  while [ "$attempt" -le "$PUSH_RETRIES" ]; do
    log "Push (próba $attempt/$PUSH_RETRIES)..."
    if git push "$REMOTE" "$BRANCH"; then
      return 0
    fi
    # Zdalna gałąź mogła się przesunąć — spróbuj rebase i push jeszcze raz
    if ! git pull --rebase --autostash "$REMOTE" "$BRANCH"; then
      git rebase --abort 2>/dev/null || true
    fi
    if [ "$attempt" -eq 2 ] && push_single_commits; then
      return 0
    fi
    log "Push nieudany, czekam ${delay}s..."
    sleep "$delay"
    delay=$(( delay * 2 ))
    attempt=$(( attempt + 1 ))
  done
  return 1
}

# ------------------------------ Główna pętla ---------------------------------
log "Repo: $(pwd) | branch=$BRANCH remote=$REMOTE"
log "Batch: max ${BATCH_SIZE} plików / ${BATCH_MB} MB | min ${MIN_FILES} plików"
[ "$DRY_RUN" -eq 1 ] && log "TRYB DRY-RUN — nic nie zostanie zacommitowane."

commit_no=0
skipped_big=0

while [ "$RUNNING" -eq 1 ]; do
  PENDING="$(pending_count)"

  if [ "$PENDING" -eq 0 ]; then
    [ "$ONCE" -eq 1 ] && break
    log "Brak zmian. Czekam ${WAIT_MINUTES} min..."
    sleep $(( WAIT_MINUTES * 60 )) || break
    continue
  fi

  if [ "$PENDING" -lt "$MIN_FILES" ] && [ "$ONCE" -eq 0 ]; then
    log "Za mało plików ($PENDING < $MIN_FILES). Czekam ${WAIT_MINUTES} min..."
    sleep $(( WAIT_MINUTES * 60 )) || break
    continue
  fi

  # --- Zbuduj batch: limit po liczbie plików ORAZ po sumarycznym rozmiarze ---
  batch_list="$(mktemp)" || die "mktemp"
  count=0
  bytes=0
  while IFS= read -r -d '' f; do
    sz="$(file_size "$f")"
    if [ "$sz" -gt "$MAX_FILE_BYTES" ]; then
      log "POMIJAM zbyt duży plik ($(( sz / 1024 / 1024 )) MB > ${MAX_FILE_MB} MB): $f"
      skipped_big=$(( skipped_big + 1 ))
      continue
    fi
    if [ "$count" -gt 0 ] && { [ "$count" -ge "$BATCH_SIZE" ] || [ $(( bytes + sz )) -gt "$BATCH_BYTES" ]; }; then
      break
    fi
    printf '%s\0' "$f" >>"$batch_list"
    count=$(( count + 1 ))
    bytes=$(( bytes + sz ))
  done < <(pending_files_z)

  if [ "$count" -eq 0 ]; then
    rm -f "$batch_list"
    log "Nic do zacommitowania (pozostały tylko pominięte pliki: $skipped_big). Koniec."
    break
  fi

  log "Batch #$(( commit_no + 1 )): ${count} plików, $(( bytes / 1024 / 1024 )) MB (z ${PENDING} oczekujących)."

  if [ "$DRY_RUN" -eq 1 ]; then
    rm -f "$batch_list"
    [ "$ONCE" -eq 1 ] && break
    continue
  fi

  # `git add -A --pathspec-from-file` obsługuje też usunięcia plików
  if ! git add -A --pathspec-from-file="$batch_list" --pathspec-file-nul; then
    rm -f "$batch_list"
    die "git add nie powiódł się."
  fi
  rm -f "$batch_list"

  if git diff --cached --quiet; then
    log "Nic nie trafiło do indeksu — pomijam commit."
    continue
  fi

  commit_no=$(( commit_no + 1 ))
  git commit -q -m "${COMMIT_MSG} (batch ${commit_no}, ${count} plików)" || die "git commit nie powiódł się."

  if ! do_push; then
    die "Push nie powiódł się po ${PUSH_RETRIES} próbach. Commity są lokalnie — popraw i uruchom ponownie."
  fi
  log "Batch #${commit_no} wysłany."

  if [ "$GC_EVERY" -gt 0 ] && [ $(( commit_no % GC_EVERY )) -eq 0 ]; then
    log "Uruchamiam git gc --auto..."
    git gc --auto --quiet || true
  fi
done

log "Zakończone. Wysłanych batchy: ${commit_no}. Pominiętych dużych plików: ${skipped_big}."
log "Sprawdź: git status --short | head"
