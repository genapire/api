#!/usr/bin/env bash
#
# update-stats.sh — Zlicza artystów, albumy i unikalne gatunki muzyczne,
# generuje stats.json, status.json, stats.xml oraz aktualizuje README.md i index.md
#
set -euo pipefail

TARGET_DIR="/mnt/radiomore/raiomore/compose_projects/genapire-api"
if [ -d "$TARGET_DIR" ]; then
  cd "$TARGET_DIR"
else
  cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
fi

DRY_RUN=0
WORKERS=8

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --workers) WORKERS="$2"; shift ;;
    -h|--help)
      echo "Użycie: $0 [--dry-run] [--workers N]"
      echo "  Zlicza artystów, albumy oraz gatunki i aktualizuje README.md, index.md, stats.json, status.json oraz stats.xml."
      exit 0
      ;;
    *) echo "Nieznany parametr: $1" >&2; exit 2 ;;
  esac
  shift
done

node - "$DRY_RUN" "$WORKERS" << 'NODE_SCRIPT'
const { Worker, isMainThread, parentPort, workerData } = require("worker_threads");
const fs = require("fs");
const path = require("path");

const dryRun = process.argv[2] === "1";
const numWorkers = parseInt(process.argv[3] || "8", 10);
const rootDir = process.cwd();
const artistsDir = path.join(rootDir, "artists");

if (!fs.existsSync(artistsDir)) {
  console.error("BŁĄD: Nie znaleziono katalogu artists pod: " + artistsDir);
  process.exit(1);
}

const workerCode = `
  const { parentPort, workerData } = require("worker_threads");
  const fs = require("fs");
  const path = require("path");
  const { chunk, root } = workerData;
  let totalAlbums = 0;
  let totalAssignments = 0;
  const counts = new Map();

  for (const artist of chunk) {
    const albumsDir = path.join(root, artist, "albums");
    let albumFiles;
    try {
      albumFiles = fs.readdirSync(albumsDir);
    } catch {
      continue;
    }
    for (const f of albumFiles) {
      if (!f.endsWith(".json")) continue;
      totalAlbums++;
      let content;
      try {
        content = fs.readFileSync(path.join(albumsDir, f), "utf8");
      } catch {
        continue;
      }
      const m = content.match(/"genres":\\s*\\[([\\s\\S]*?)\\]/);
      if (m) {
        const items = m[1].match(/"([^"]+)"/g);
        if (items) {
          for (const item of items) {
            totalAssignments++;
            const g = item.slice(1, -1).toLowerCase().trim();
            if (g) counts.set(g, (counts.get(g) || 0) + 1);
          }
        }
      }
    }
  }
  parentPort.postMessage({ totalAlbums, totalAssignments, genres: [...counts.entries()] });
`;

async function main() {
  console.log("Zbieranie statystyk dla GenAPIre...");
  console.time("Czas obliczeń");

  let totalArtists = 0;
  const artistsJsonPath = path.join(rootDir, "artists.json");
  if (fs.existsSync(artistsJsonPath)) {
    try {
      const parsed = JSON.parse(fs.readFileSync(artistsJsonPath, "utf8"));
      if (Array.isArray(parsed.artists)) {
        totalArtists = parsed.artists.length;
      }
    } catch {}
  }

  const artistDirs = fs.readdirSync(artistsDir, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name);

  if (totalArtists === 0) {
    totalArtists = artistDirs.length;
  }

  const chunkSize = Math.ceil(artistDirs.length / numWorkers);
  const workerPromises = [];
  const genreCounts = new Map();
  let totalAlbums = 0;
  let totalGenreAssignments = 0;

  for (let i = 0; i < numWorkers; i++) {
    const chunk = artistDirs.slice(i * chunkSize, (i + 1) * chunkSize);
    if (chunk.length === 0) continue;

    const p = new Promise((resolve, reject) => {
      const worker = new Worker(workerCode, {
        eval: true,
        workerData: { chunk, root: artistsDir }
      });
      worker.on("message", res => {
        totalAlbums += res.totalAlbums;
        totalGenreAssignments += res.totalAssignments;
        for (const [k, v] of res.genres) {
          genreCounts.set(k, (genreCounts.get(k) || 0) + v);
        }
        resolve();
      });
      worker.on("error", reject);
      worker.on("exit", code => {
        if (code !== 0) reject(new Error(`Worker exited with code ${code}`));
      });
    });
    workerPromises.push(p);
  }

  await Promise.all(workerPromises);
  console.timeEnd("Czas obliczeń");

  const uniqueGenres = genreCounts.size;
  const topGenresList = [...genreCounts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 25)
    .map(([genre, count], idx) => ({
      rank: idx + 1,
      genre,
      count,
      formatted: count.toLocaleString("en-US"),
      percentage: totalAlbums > 0 ? ((count / totalAlbums) * 100).toFixed(1) + "%" : "0.0%"
    }));

  const formatBadge = num => {
    if (num >= 1000000) return (num / 1000000).toFixed(2) + "M+";
    if (num >= 1000) return (num / 1000).toFixed(1) + "k+";
    return String(num);
  };

  const artistsFmt = totalArtists.toLocaleString("en-US");
  const albumsFmt = totalAlbums.toLocaleString("en-US");
  const uniqueGenresFmt = uniqueGenres.toLocaleString("en-US");
  const assignmentsFmt = totalGenreAssignments.toLocaleString("en-US");

  const artistsBadge = formatBadge(totalArtists);
  const albumsBadge = formatBadge(totalAlbums);
  const assignmentsBadge = formatBadge(totalGenreAssignments);

  console.log("-----------------------------------------");
  console.log(`Artyści:           ${artistsFmt}`);
  console.log(`Albumy:            ${albumsFmt}`);
  console.log(`Unikalne gatunki:  ${uniqueGenresFmt}`);
  console.log(`Łącznie tagów:     ${assignmentsFmt}`);
  console.log("-----------------------------------------");
  console.log("Top 5 gatunków:");
  for (const g of topGenresList.slice(0, 5)) {
    console.log(`  ${g.rank}. ${g.genre.padEnd(18)} : ${g.formatted.padStart(8)} (${g.percentage})`);
  }
  console.log("-----------------------------------------");

  if (dryRun) {
    console.log("[DRY RUN] Pomijam zapisywanie plików.");
    return;
  }

  const nowIso = new Date().toISOString();

  // 1. stats.json i status.json
  const statsPayload = {
    status: "ok",
    updatedAt: nowIso,
    artists: totalArtists,
    artistsFormatted: artistsFmt,
    albums: totalAlbums,
    albumsFormatted: albumsFmt,
    uniqueGenres,
    uniqueGenresFormatted: uniqueGenresFmt,
    totalGenreAssignments,
    totalGenreAssignmentsFormatted: assignmentsFmt,
    badges: {
      artists: artistsBadge,
      albums: albumsBadge,
      genres: String(uniqueGenres),
      assignments: assignmentsBadge
    },
    topGenres: topGenresList
  };

  fs.writeFileSync(path.join(rootDir, "stats.json"), JSON.stringify(statsPayload, null, 2) + "\n", "utf8");
  fs.writeFileSync(path.join(rootDir, "status.json"), JSON.stringify(statsPayload, null, 2) + "\n", "utf8");
  console.log("Zapisano stats.json oraz status.json");

  // 2. stats.xml
  const xmlTopGenres = topGenresList
    .map(g => `    <genre rank="${g.rank}" name="${g.genre}" count="${g.count}" percentage="${g.percentage}" />`)
    .join("\n");

  const statsXml = `<?xml version="1.0" encoding="UTF-8"?>
<stats>
  <status>ok</status>
  <updatedAt>${nowIso}</updatedAt>
  <artists>${totalArtists}</artists>
  <albums>${totalAlbums}</albums>
  <uniqueGenres>${uniqueGenres}</uniqueGenres>
  <totalGenreAssignments>${totalGenreAssignments}</totalGenreAssignments>
  <topGenres>
${xmlTopGenres}
  </topGenres>
</stats>
`;
  fs.writeFileSync(path.join(rootDir, "stats.xml"), statsXml, "utf8");
  console.log("Zapisano stats.xml");

  // Tabela podsumowująca
  const summaryTable = [
    "| Metric | Count |",
    "| :--- | :--- |",
    `| **Artists** | ${artistsFmt} |`,
    `| **Albums** | ${albumsFmt} |`,
    `| **Unique Genres** | ${uniqueGenresFmt} |`,
    `| **Total Genre Assignments** | ${assignmentsFmt} |`
  ].join("\n");

  // Tabela top 20 gatunków
  const topGenresTable = [
    "| Rank | Genre | Albums | Share |",
    "| :---: | :--- | :--- | :--- |",
    ...topGenresList.slice(0, 20).map(g => `| ${g.rank} | **${g.genre}** | ${g.formatted} | ${g.percentage} |`)
  ].join("\n");

  const fullStatsMarkdown = [
    "### Database Overview",
    "",
    summaryTable,
    "",
    "### Top 20 Genres",
    "",
    topGenresTable
  ].join("\n");

  const badgesMarkdown = [
    `[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)`,
    `[![Discord](https://img.shields.io/badge/Discord-Join%20Chat-5865F2?logo=discord&logoColor=white)](https://discord.gg/rwJcE5Zwez)`,
    `[![Artists](https://img.shields.io/badge/Artists-${artistsBadge.replace("+", "%2B")}-blue)](https://genapire.mobulum.com)`,
    `[![Albums](https://img.shields.io/badge/Albums-${albumsBadge.replace("+", "%2B")}-informational)](https://genapire.mobulum.com)`,
    `[![Unique Genres](https://img.shields.io/badge/Genres-${uniqueGenres}-purple)](https://genapire.mobulum.com)`,
    `[![Genre Assignments](https://img.shields.io/badge/Assignments-${assignmentsBadge.replace("+", "%2B")}-success)](https://genapire.mobulum.com)`
  ].join("\n");

  // 3. Aktualizacja README.md
  const readmePath = path.join(rootDir, "README.md");
  if (fs.existsSync(readmePath)) {
    let content = fs.readFileSync(readmePath, "utf8");
    const statsSectionRegex = /<!-- STATS_START -->[\s\S]*?<!-- STATS_END -->/;
    if (statsSectionRegex.test(content)) {
      content = content.replace(statsSectionRegex, `<!-- STATS_START -->\n${fullStatsMarkdown}\n<!-- STATS_END -->`);
    }
    const badgesRegex = /<!-- BADGES_START -->[\s\S]*?<!-- BADGES_END -->/;
    if (badgesRegex.test(content)) {
      content = content.replace(badgesRegex, `<!-- BADGES_START -->\n${badgesMarkdown}\n<!-- BADGES_END -->`);
    }
    fs.writeFileSync(readmePath, content, "utf8");
    console.log("Zaktualizowano README.md");
  }

  // 4. Aktualizacja index.md
  const indexPath = path.join(rootDir, "index.md");
  if (fs.existsSync(indexPath)) {
    let content = fs.readFileSync(indexPath, "utf8");
    const statsSectionRegex = /<!-- STATS_START -->[\s\S]*?<!-- STATS_END -->/;
    if (statsSectionRegex.test(content)) {
      content = content.replace(statsSectionRegex, `<!-- STATS_START -->\n${fullStatsMarkdown}\n<!-- STATS_END -->`);
    } else {
      const oldStatsRegex = /# Stats[\s\S]*?(?=# License|\Z)/;
      if (oldStatsRegex.test(content)) {
        content = content.replace(oldStatsRegex, `# Stats\n\n<!-- STATS_START -->\n${fullStatsMarkdown}\n<!-- STATS_END -->\n\n`);
      }
    }
    const badgesRegex = /<!-- BADGES_START -->[\s\S]*?<!-- BADGES_END -->/;
    if (badgesRegex.test(content)) {
      content = content.replace(badgesRegex, `<!-- BADGES_START -->\n${badgesMarkdown}\n<!-- BADGES_END -->`);
    }
    fs.writeFileSync(indexPath, content, "utf8");
    console.log("Zaktualizowano index.md");
  }

  console.log("Gotowe!");
}

main().catch(err => {
  console.error("Błąd podczas aktualizacji statystyk:", err);
  process.exit(1);
});
NODE_SCRIPT
