# [kjaer.io](https://kjaer.io)

[![Build Status](https://travis-ci.com/MaximeKjaer/kjaer.io.svg?branch=master)](https://travis-ci.com/MaximeKjaer/kjaer.io)

My personal blog. Built with Jekyll.

[![Screenshot of my website](https://i.imgur.com/QVTzndb.jpg "Screenshot of my website")](https://i.imgur.com/QVTzndb.jpg)

## Installation

The site builds with Jekyll, but also has a few NPM dependencies. To install all dependencies, you'll need Node and npm, as well as Ruby and bundler. You can then run:

```
bundle install
npm install
```

## Writing a post
See the [Jekyll Documentation](https://jekyllrb.com/docs/posts/) for how to create a Jekyll post.

### Supported YAML Frontmatter fields
| Option | Description | Default |
| :----- | :---------- | :------ |
| `title` | The title of the post | ` ` |
| `description` | A brief description of the post. This description *may* be used by search engines, and *will* be used when the post is shared on Facebook and Twitter. | `site.description`
| `image` | The hero image | `site.hero.image` |
| `fallback-color` | Hex color code of the color (in quotes) that will be shown behind the hero image. This is especially useful if the hero image fails to load, or takes a while to do so. If we show the image's average color, the flash of the image appearing will be less harsh. I've been using [Color Thief](http://lokeshdhakar.com/projects/color-thief/) to get this average color. | `site.hero.fallback-color` |
| `comments` | If `false`, there won't be a Disqus comment field on the post | `true` |
| `published` | If `false`, the post won't be rendered or published | `true` |
| `edited` | If `true`, there will be a link leading to the post's GitHub edit history at the bottom of the post | `false` |
| `updated` | If set to a date, the update date will be displayed, and `edited` will be considered `true` | ` ` |
| `hn` | If a HN link is specified, there will be a link leading to the HN discussion at the bottom of the post | ` ` |

### Excerpt separator
On the front page of the site, excerpts of every post are shown. On this site, a post "breaks" on the first HTML comment by default, so the end of the front page's excerpt can be marked as such in a post:

```markdown
---
title: How to define excerpts within the post
---

Here's an intro. See you after the break!

<!-- More -->

Here's the rest of the post.
```

### Sample post
```markdown
---
title: A sample post
image: /images/hero/example.jpg
fallback-color: "#0f45b7"
description: A sample post showing how YAML Frontmatter works on this site.
comments: false
edited: true
hn: https://news.ycombinator.com/item?id=12114523
---

This post is an example.

<!-- More -->

This is the end of the article!
```

## Building the site

### Installing dependencies

```console
$ rbenv install
$ rbenv reshash
$ bundle install
$ npm install
$ sudo apt install graphviz
```

### Development

To serve the site locally with incremental builds and autorefresh, run:

```console
$ npm run serve
```

### Production

To build the site for production, run:

```console
$ npm run build
```

To prepare the site for production, a few additional steps are taken.

- Autoprefixer ensures that all the CSS is compatible with the 2 last versions if every browser
- Hero images are resized to the breakpoints defined in `_config.yml`
- Assets are Zopfli-compressed
