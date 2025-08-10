---
#
# By default, content added below the "---" mark will appear in the home page
# between the top bar and the list of recent posts.
# To change the home page layout, edit the _layouts/home.html file.
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
#
layout: home
title: "Welcome to Gen(API)re"
---

## What

GenAPIre is a response to the need for free access to music genres describing your music, provided in a normalized way, without unnecessary complexity.
You can use the REST API and get a response in JSON or XML format. We can add more formats if needed. You can contribute too. Just let’s talk about it.
Available to everyone, free, forever. You can buy me a coffee if you want. But you don’t have to. I’m glad I could help you.

## Why

Like many people, I privately own a large collection of CDs and vinyl records. I love them. At some point, however, you may want to transfer your physical music library to a digital one and create your own digital music collection. You might encounter a problem related to music genres.
There are several services like https://musicbrainz.org or https://www.last.fm, and great tools like https://beets.io which I admire and highly recommend.
Unfortunately, I’ve encountered issues with the quality of music genres in these sources. Additionally, as a developer, I wanted to make them available via a simple REST API for everyone.
That’s how genAPIre was created, which builds knowledge about music genres for your and my music from various sources. Thanks to those mentioned above and github.com, of course.

## How

To use this knowledge base, you need an HTTP client capable of making simple requests. Let’s do it now with curl:


### JSON

```bash
curl "https://genapire.online/artists/ABBA/albums/Waterloo.json"
```

The response is as follows:
```json
{
    "genres": [
        "pop",
        "70s",
        "disco"
    ]
}
```


### XML

Now the same for XML:


```bash
curl "https://genapire.online/artists/ABBA/albums/Waterloo.xml"
```

The response is as follows:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<album>
    <genres>
        <genre>pop</genre>
        <genre>70s</genre>
        <genre>disco</genre>
    </genres>
</album>
```


## Free, forever

Feel free to use however you like but please do not sell it. It is FREE for everyone! FOREVER. You can buy me a coffee if you like to thank me.

- [PayPal](https://paypal.me/zenedithPL)
- [Ko-Fi](https://ko-fi.com/K3K11ABGW5)
- [Patreon](https://patreon.com/Zenedith)

## License

The genapire is licensed under the [MIT license](https://opensource.org/licenses/MIT).