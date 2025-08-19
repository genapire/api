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
curl "https://genapire.online/artists/ABBA/albums/Waterloo%20(Deluxe%20Edition).json"
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
curl "https://genapire.online/artists/ABBA/albums/Waterloo%20(Deluxe%20Edition).xml"
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
curl "https://genapire.online/artists/{artist}/albums/{album}.(xml|json)"
```

But you can get more information.


### GET genres for artist

```bash
curl "https://genapire.online/artists/{artist}.(xml|json)"
```

An example for ABBA:

```bash
curl "https://genapire.online/artists/ABBA.json"
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
curl "https://genapire.online/artists/{artist}/albums.(xml|json)"
```

Now let’s fetch all available albums with genres for ABBA:

```bash
curl "https://genapire.online/artists/ABBA/albums.json"
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
curl "https://genapire.online/artists.(xml|json)"
```

I won’t show the response because it’s long and changes over time. I’m constantly working on it—for myself and for
you :)

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

#### Artists: 11404
#### Albums: 149022


# License

The genAPIre is licensed under the [MIT license](https://opensource.org/licenses/MIT).