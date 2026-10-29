# GenAPIre API

<!-- BADGES_START -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Discord](https://img.shields.io/badge/Discord-Join%20Chat-5865F2?logo=discord&logoColor=white)](https://discord.gg/rwJcE5Zwez)
[![Artists](https://img.shields.io/badge/Artists-29.2k%2B-blue)](https://genapire.mobulum.com)
[![Albums](https://img.shields.io/badge/Albums-333.1k%2B-informational)](https://genapire.mobulum.com)
[![Unique Genres](https://img.shields.io/badge/Genres-563-purple)](https://genapire.mobulum.com)
[![Genre Assignments](https://img.shields.io/badge/Assignments-1.13M%2B-success)](https://genapire.mobulum.com)
<!-- BADGES_END -->

> Free, open, static REST API providing normalized, curated music genres for artists and albums in JSON and XML.

---

## What

**GenAPIre** is a response to the need for free, open access to normalized music genres describing your music library, without unnecessary schema complexity.
You can query the REST API directly using any standard HTTP client and receive responses in **JSON** or **XML** format.
Hosted statically via GitHub Pages and CDN for high reliability, maximum speed, and zero rate limits.

Available to everyone, free, forever.

---

## Why

When organizing personal digital music collections (CD and vinyl rips, FLAC/MP3 files), tagging music genres consistently is often difficult. Existing metadata providers either lack coverage, have excessive clutter and conflicting tags, or require complex API keys with strict rate limits.

**GenAPIre** solves this by pre-resolving, cleaning, and normalizing genre data into a static, highly available API structure:
- **Cleaned & Normalized**: Curated genres matched against validated whitelists.
- **Fast & Static**: Zero rate limits, zero server load bottlenecks.
- **Dual Format**: Native support for both JSON and XML endpoints.

---

## How to Use

All you need is an HTTP client (`curl`, `fetch`, `axios`, etc.) capable of making simple GET requests.

### Base URL

```text
https://genapire.mobulum.com
```

Alternative (GitHub Pages):
```text
https://genapire.github.io/api
```

---

## API Endpoints

### 1. Album Genres
Fetch genres describing a specific album:

```bash
# JSON
curl "https://genapire.mobulum.com/artists/ABBA/albums/Waterloo%20(Deluxe%20Edition).json"

# XML
curl "https://genapire.mobulum.com/artists/ABBA/albums/Waterloo%20(Deluxe%20Edition).xml"
```

**JSON Response:**
```json
{
  "genres": [
    "pop",
    "70s",
    "disco",
    "swedish"
  ]
}
```

### 2. Artist Top Genres
Fetch top aggregated genres for an artist:

```bash
# JSON
curl "https://genapire.mobulum.com/artists/ABBA.json"

# XML
curl "https://genapire.mobulum.com/artists/ABBA.xml"
```

**JSON Response:**
```json
{
  "genres": [
    "pop",
    "disco",
    "70s",
    "swedish",
    "80s"
  ]
}
```

### 3. Artist Album List
Fetch all indexed albums for an artist:

```bash
# JSON
curl "https://genapire.mobulum.com/artists/ABBA/albums.json"

# XML
curl "https://genapire.mobulum.com/artists/ABBA/albums.xml"
```

### 4. Full Artist Catalog
Fetch all available artists in the GenAPIre database:

```bash
curl "https://genapire.mobulum.com/artists.json"
curl "https://genapire.mobulum.com/artists.xml"
```

### 5. Database Statistics & Status
Retrieve quantitative metrics and top genres across the entire database:

```bash
# JSON (stats or status alias)
curl "https://genapire.mobulum.com/stats.json"
curl "https://genapire.mobulum.com/status.json"

# XML
curl "https://genapire.mobulum.com/stats.xml"
```

**JSON Response format:**
- `status` *(string)*: Operational status (`"ok"`).
- `updatedAt` *(string)*: ISO 8601 timestamp of the last statistics calculation.
- `artists` *(number)* / `artistsFormatted` *(string)*: Total artists indexed.
- `albums` *(number)* / `albumsFormatted` *(string)*: Total albums indexed.
- `uniqueGenres` *(number)* / `uniqueGenresFormatted` *(string)*: Total unique distinct genres.
- `totalGenreAssignments` *(number)* / `totalGenreAssignmentsFormatted` *(string)*: Total genre tags assigned across all albums.
- `badges` *(object)*: Precomputed badge strings for quick shields.io display.
- `topGenres` *(array)*: Top 25 genres sorted by frequency, with rank, count, formatted number, and library share percentage.

---

## Stats

<!-- STATS_START -->
### Database Overview

| Metric | Count |
| :--- | :--- |
| **Artists** | 29,191 |
| **Albums** | 333,063 |
| **Unique Genres** | 563 |
| **Total Genre Assignments** | 1,125,338 |

### Top 20 Genres

| Rank | Genre | Albums | Share |
| :---: | :--- | :--- | :--- |
| 1 | **jazz** | 49,963 | 15.0% |
| 2 | **rock** | 49,532 | 14.9% |
| 3 | **electronic** | 43,378 | 13.0% |
| 4 | **pop** | 42,474 | 12.8% |
| 5 | **female-vocalists** | 35,375 | 10.6% |
| 6 | **soul** | 24,746 | 7.4% |
| 7 | **oldies** | 23,710 | 7.1% |
| 8 | **dance** | 23,631 | 7.1% |
| 9 | **classic-rock** | 22,902 | 6.9% |
| 10 | **instrumental** | 21,867 | 6.6% |
| 11 | **80s** | 19,218 | 5.8% |
| 12 | **blues** | 17,957 | 5.4% |
| 13 | **classical** | 17,934 | 5.4% |
| 14 | **ambient** | 17,685 | 5.3% |
| 15 | **hip-hop** | 17,509 | 5.3% |
| 16 | **60s** | 17,176 | 5.2% |
| 17 | **folk** | 16,011 | 4.8% |
| 18 | **house** | 15,605 | 4.7% |
| 19 | **trance** | 15,542 | 4.7% |
| 20 | **alternative** | 14,655 | 4.4% |
<!-- STATS_END -->

---

## Maintenance & Automation

The repository includes automation scripts to keep stats and git pushes manageable:

- **`update-stats.sh`**: Scans the database using worker threads, calculates genre frequencies, generates `stats.json`, `status.json`, `stats.xml`, and updates statistics tables in `README.md` and `index.md`.
  ```bash
  ./update-stats.sh [--dry-run] [--workers 8]
  ```
- **`batch-push-v3.sh`**: Optimized batch committer and pusher for large file counts (10,000 files per commit). Uses flock locking, NVMe path acceleration, and exponential backoff retry.
  ```bash
  ./batch-push-v3.sh [--batch-size 10000] [--branch master] [--remote origin] [--dry-run]
  ```

---

## FAQ

**Q: How can I contact you?**  
**A:** Join our Discord server: [https://discord.gg/rwJcE5Zwez](https://discord.gg/rwJcE5Zwez)

**Q: Why isn't artist "X" or album "Y" available?**  
**A:** The database expands continuously from radio station playlists and crawl pipelines. Contributions and requests are welcome!

**Q: Are there rate limits?**  
**A:** No. Since data is served statically via GitHub Pages and CDN, there are zero rate limits or API key requirements.

**Q: Is there a plugin for Jellyfin or Beets?**  
**A:** Yes, plugins are under active development, including the [Jellyfin GenAPIre Plugin](https://github.com/genapire/jellyfin-genapire-plugin).

---

## Free, Forever

Feel free to use however you like, but please do not sell it. It is FREE for everyone! FOREVER. You can buy me a coffee if you want to support this project:

- [PayPal](https://paypal.me/zenedithPL)
- [Ko-Fi](https://ko-fi.com/K3K11ABGW5)
- [Patreon](https://patreon.com/Zenedith)

---

## License

GenAPIre is licensed under the [MIT License](https://opensource.org/licenses/MIT).
