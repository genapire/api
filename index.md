---
#
# By default, content added below the "---" mark will appear in the home page
# between the top bar and the list of recent posts.
# To change the home page layout, edit the _layouts/home.html file.
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
#
layout: home
title: "Welcome to GenAPIre"
---

<!-- BADGES_START -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Discord](https://img.shields.io/badge/Discord-Join%20Chat-5865F2?logo=discord&logoColor=white)](https://discord.gg/rwJcE5Zwez)
[![Artists](https://img.shields.io/badge/Artists-29.2k%2B-blue)](https://genapire.mobulum.com)
[![Albums](https://img.shields.io/badge/Albums-333.1k%2B-informational)](https://genapire.mobulum.com)
[![Unique Genres](https://img.shields.io/badge/Genres-563-purple)](https://genapire.mobulum.com)
[![Genre Assignments](https://img.shields.io/badge/Assignments-1.13M%2B-success)](https://genapire.mobulum.com)
<!-- BADGES_END -->

# What

GenAPIre is a response to the need for free access to music genres describing your music, provided in a normalized way,
without unnecessary complexity.
You can use the REST API and get a response in JSON or XML format. More formats can be added if needed. You can
contribute too—just reach out!
Available to everyone, free, forever. You can buy me a coffee if you want, but you don’t have to. I’m glad I could help.

# Why

Like many people, I privately own a large collection of CDs and vinyl records. I love them. At some point, however, you
may want to transfer your physical music library to a digital one and create your own digital music collection. You
might encounter a problem related to music genres.
There are several services like [https://musicbrainz.org](https://musicbrainz.org)
or [https://www.last.fm](https://musicbrainz.org), and great tools like [https://beets.io](https://musicbrainz.org)
which I admire and highly recommend.
Unfortunately, I’ve encountered issues with the quality of music genres in these sources. Additionally, as a developer,
I wanted to make them available via a simple REST API for everyone.
That’s how genAPIre was created, which builds knowledge about music genres for your and my music from various sources.
Thanks to those mentioned above and github.com, of course.

# How

To use this knowledge base, you need an HTTP client capable of making simple requests. Let’s do it now with curl:

## JSON

```bash
curl "https://genapire.mobulum.com/artists/ABBA/albums/Waterloo%20(Deluxe%20Edition).json"
```

The response is as follows:

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

## XML

Now the same for XML:

```bash
curl "https://genapire.mobulum.com/artists/ABBA/albums/Waterloo%20(Deluxe%20Edition).xml"
```

The response is as follows:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<album>
  <genres>
    <genre>pop</genre>
    <genre>70s</genre>
    <genre>disco</genre>
    <genre>swedish</genre>
  </genres>
</album>
```

## API

So, to get genres for a given artist and album, just call this endpoint:

### GET genres

```bash
curl "https://genapire.mobulum.com/artists/{artist}/albums/{album}.(xml|json)"
```

But you can get more information.

### GET genres for artist

```bash
curl "https://genapire.mobulum.com/artists/{artist}.(xml|json)"
```

An example for ABBA:

```bash
curl "https://genapire.mobulum.com/artists/ABBA.json"
```

Response:

```json
{
  "genres": [
    "pop",
    "disco",
    "70s",
    "swedish",
    "80s",
    "spanish",
    "rock",
    "christmas"
  ]
}
```

### GET albums for artist

```bash
curl "https://genapire.mobulum.com/artists/{artist}/albums.(xml|json)"
```

Now let’s fetch all available albums with genres for ABBA:

```bash
curl "https://genapire.mobulum.com/artists/ABBA/albums.json"
```

```json
{
  "artist": "ABBA",
  "albums": [
    "Abba",
    "ABBA Gold",
    "Abba Gold Anniversary Edition",
    "Arrival",
    "Gracias Por La Musica (Deluxe Edition)",
    "Live At Wembley Arena",
    "More ABBA Gold",
    "Oro -Grandes Exitos-",
    "Ring Ring",
    "Ring Ring (Deluxe Edition)",
    "Super Trouper",
    "Thank You For The Music",
    "The Album",
    "The Essential Collection",
    "The Singles (The First Fifty Years)",
    "The Visitors",
    "The Visitors (Deluxe Edition)",
    "Voulez-Vous",
    "Voyage",
    "Waterloo",
    "Waterloo (Deluxe Edition)"
  ]
}
```

Similarly for XML—just change the extension.

### GET available artists

There’s one more way to use genAPIre: fetch all available artists in genAPIre with genres for their albums.

```bash
curl "https://genapire.mobulum.com/artists.(xml|json)"
```

### GET database statistics and status

Fetch real-time database metrics, genre totals, and top genres distribution:

```bash
# JSON (available as /stats.json and /status.json)
curl "https://genapire.mobulum.com/stats.json"
curl "https://genapire.mobulum.com/status.json"

# XML
curl "https://genapire.mobulum.com/stats.xml"
```

# FAQ

**Q: How can I contact you?**

**A:** Use [discord](https://discord.gg/rwJcE5Zwez)

**Q: Why isn't artist "x" or album "y" for artist "z" available in genAPIre ?**

**A:** This may change over time; you can help me add it if you want.

**Q: Why REST API? I need access it using technology "x".**

**A:** REST API works great for managing this kind of information, i.e., resources. We have artists, artists have
albums, described by genres.
For me, the biggest advantage was that I can provide different representations (JSON, XML) and host them on github.com,
since it's a collection of directories and files that can be easily hosted statically.
If your need can be met while maintaining these assumptions, then it's a yes.

**Q: Will you create a plugin for jellyfin/beets/any ?**

**A:** I have thought about it and have already started some work on a plugin for [jellyfin](https://github.com/genapire/jellyfin-genapire-plugin). Work in progress ...
I would gladly accept help in this area. The list of contributions can't stay empty! :)

# Free, forever

Feel free to use however you like but please do not sell it. It is FREE for everyone! FOREVER. You can buy me a coffee
if you like to thank me.

- [PayPal](https://paypal.me/zenedithPL)
- [Ko-Fi](https://ko-fi.com/K3K11ABGW5)
- [Patreon](https://patreon.com/Zenedith)

# Stats

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

# License

The genAPIre is licensed under the [MIT license](https://opensource.org/licenses/MIT).
