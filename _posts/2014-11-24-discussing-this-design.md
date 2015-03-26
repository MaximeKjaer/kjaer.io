---
layout: post
title: Discussing this design
description: I think I'm done.
image: stickers.jpg
---

With this post, I am pushing a bit of a redesign.

### The Creative Process

> 1. This is awesome  
> 2. This is tricky 
> 3. This is shit 
> 4. I am shit 
> 5. This might be ok 
> 6. This is awesome  

Despite being stuck for quite a while at steps 2 to 4, I think that I may finally have reached the point where I am happy with the site. I'm actually a bit proud of it, to be honest!

## A quick overview of this design

The first thing that I want to mention is that I wrote it by hand. I did use a few of [Codyhouse's "nuggets"](http://codyhouse.co/), but the rest was painstakingly written by me, because I wanted the absolute pixel-perfect control that this offers.

On the technical side of things, I'm using the [Jekyll](http://jekyllrb.com/) platform, based off of the [Jekyll Now](https://github.com/barryclark/jekyll-now) preset (which has been largely modified to meet my needs, so much so that there barely is anything left from the original repo). I tried to make it as modular as even possible as to make modifications easy and have a lot of reusability. You can check out the [GitHub repo](https://github.com/MaximeKjaer/MaximeKjaer.github.io) if you want to have a look for yourself.

But the main goal of this post was to discuss design decisions, so why don't we dive into that now:

<!--- Separator -->

The header features a pretty picture of Lausanne, the city in which I study. I chose this picture for multiple reasons: firstly, it was a bit dark, which means that I easily can place white text over it - that's the practical reason. Then, the picture was taken right next to where I live, which adds a personal touch to it. The fact that it was taken during the winter is just a bonus, really, because I **love** snow; the first snowfall of the year is like Christmas to me.

The more I thought about making the header personal, the more ideas came up. Even though the site was meant to be a blog at first, I added a sort of [portfolio]({{ site.baseurl }}/about), a sentence or two about who I am, links to my SoundCloud, Instagram...

For a moment, I was afraid my color scheme was a bit dull. It needed some eye candy. And that's exactly what the button in the middle of the header is. Again, for it to be in the header, it had to mean something to me. Combining candy and personal details and preferences, I ended up with the colors of Haribo Peaches (my favorites!).

For the rest of the site, I wanted a Sans-Serif font (that's just a personal preference, again), and just plain *simplicity*. The safe bet for a design that ages well isn't flat design or material design (though it has some good ideas, it's a bit of a fad in my opinion - but that's for another post). No, simplicity is the only thing that won't go out of fashion.

So simplicity was the keyword, and I really did try to keep it at that. It's incredibly easy to overload a page with information, but simplifying things is actually not simple, quite ironically.

A lot of thought went into the post page. It's supposed have the same feel as the rest of the site, and to focus the reader's attention on the post itself. That's why I put the black navbar on top, which makes the intro seem a bit shorter, and an arrow at the bottom of the image, to incite the user to scroll down to the content (according to [this article](http://hugeinc.com/ideas/perspective/everybody-scrolls), what I'm doing is a combination of the two best ways to get users to scroll).

I reused the red in the icons for the links, and my `<hr>` tags are also as simple as they can get (they are meant to look like a small notch in the page). Oh, and did I mention the tiny little smiley at the bottom of my page? My old blog had that, so I just *had* to include it in this one.

I could go on for hours, but you get the bulk of it.

Does that mean that I am *completely* done? Absolutely not. I recognize that I still can make a few tweaks. This site being hosted on GitHub Pages (for now), I figured that I may as well be fully transparent with the whole process - so without further ado, here is my little to-do list:

### To-do

- Better IDs for my `#cd-placeholder1` sections.
- Add tags to posts (will fit right under "Written on ...") **only possible after self-hosting, since it requires a plugin - so consider a DigitalOcean plan**
- Try out a few other SEO tricks (just enough to get the site to actually show when googling my name).
- Make images show up on feedly.

### Done

- Alt text on all images.
- Title on the post author's picture.
- Serve scaled images.
- Register on Google Webmaster Tools:
  - Verify the site.
  - Add the [sitemap.xml]({{ site.baseurl }}/sitemap.xml).
  - Register for email alerts.
- Make pretty `<hr>`s
- Optimize the main splash image (was able to save ~2MB)
- Add a footer.
- Fix the colors on the main call-to-action button
- Fix up h1, h2... styling in posts
- Different post page.
- Splitting the CSS into different files. Some of the CSS will never be used on the front page.
- When clicking on the first blog post, there should be a noticeable difference in the page! (fixed with new post page)
- Don't load font sizes that I don't need.
- Get a logo.
- Minify CSS and JS.
- Make a better footer.
- Add an `image:` field to the YAML Front Matter in posts.
- Use the `<time>` tag for the publishing date.

So there you have it. I could keep tweaking things (and I probably will), but I'm happy with the site. Welcome!