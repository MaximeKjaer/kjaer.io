---
title: "Waiting for browser support: makeshift responsive images"
description: The new specification for responsive images isn't well supported, especially in the very devices that need it. Here's what we can do in the meantime.
image: /images/hero/bench.jpg
fallback-color: "#D4AB9B"
edited: true
---

I suffer from the most common responsive issue. As my [recent](/travis/) [post history](/web-performance-2.0/) [may attest to](/quick-cache-this/), performance matters to me. At the same time, though, I also want my images to look great on every screen, and that's not as trivial as it may sound. For a long time, it's been impossible to have high quality images of minimal size on every screen. This classic problem is *just* being solved right now by the [Responsive Issues Community Group](https://www.w3.org/community/respimg/), but the solution isn't quite ready for prime time yet.

## Responsive images, a relatively immature feature
Indeed, as of this writing, CSS `image-set` only has [62% browser support](http://caniuse.com/#feat=css-image-set) and is still very much [an editor's draft](https://drafts.csswg.org/css-images-3/#image-set-notation). The `srcset` attribute isn't much better, clocking in at [67%](http://caniuse.com/#feat=srcset), and `<picture>` is at a dismal [57%](http://caniuse.com/#feat=picture).

Now, these new specifications are backwards-compatible (as in, they won't break your site), so you could argue that mediocre support is an invalid concern. But support is mainly lacking in the very browsers that actually need this spec. As of right now, **there are no phones out there that support this specification in their default browser**. So why even bother?

<!-- More -->

As you can see in the [caniuse.com](http://caniuse.com/) table below, the `<picture>`  element is barely supported on mobile. Now, in all fairness, it does say that the current version of the default Android browser supports it, but I'd argue against that: while the current listed version officially is a WebView of Chromium 47, it has 0% global usage, so I'd say that the *de facto* current version still is 4.4.4.

![A chart of which mobile browsers support the picture element; most of them don't](/images/picture-support.png)

Sure, I could use [a polyfill](http://scottjehl.github.io/picturefill/). But I'm interested in this new spec for performance reasons, so loading and running 1500 lines of Javascript is *not* going to cut it.

## Makeshift responsiveness
So what can we do in the meantime? We need a solution that works for all (or *almost* all) users, which means that it'll have to be stringed together from well-supported technologies. Well, a few days ago, I had this random idea that I could probably emulate some basic functionality using media queries to load the correctly sized background-image.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Random thought: background-image + media query has much better support that srcset. Could be a temporary hack... <a href="https://t.co/Cd2UzEhwC6">https://t.co/Cd2UzEhwC6</a></p>&mdash; Maxime Kjaer (@maximekjaer) <a href="https://twitter.com/maximekjaer/status/702487643678965761">February 24, 2016</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

This is not an entirely new idea. Three years ago, Smashing Magazine published [an article](https://www.smashingmagazine.com/2013/07/simple-responsive-images-with-css-background-images/) suggesting that instead of using an `<img>`, we could be using `<div>`s sporting a `background-image` defined through media queries. 

Let that sink in for a second.  

In your HTML, you'd have a `<div>` play the role of an image, and its source would be defined in the CSS. Smashing Magazine is a leading voice in the world of web development, and *that* was their suggestion? I can only imagine the shriek of pain and disgust that all the W3C members working on semantics or accessibility must've let out when that article was posted. Suffice to say that I'm not replacing all my images with this "suboptimal solution", as they call it (that's quite a euphemism, Smashing Magazine!). 

As much as I like to thrash it, it's only a half bad idea. Replacing `<img>` with `<div>`s is appalling, but at the core of it, defining aptly sized background images through media queries is actually not that dumb. There are specific cases where this trick could come in handy, the banner image at the top of this post being one of them. It is indeed the background image of a `<div>`, so I feel that it's entirely justifiable from a semantic standpoint.

As a rule of thumb, you should never apply this trick to actual content, but only to the interface surrounding it &mdash; either way, if you're replacing an `<img>` with a `<div>`, you're probably doing it wrong.

To see how far media queries could take us, I tried to implement them on the banner image of this site. Adding a few media queries to each banner image sounds simple, right? But a lot of factors come into play. I had to consider what breakpoints would be optimal for my visitors, how to get Grunt and Jekyll to play along nicely, how to write maintainable code... all while thinking about caching, optimal publishing workflow and whatnot.

## How I picked my breakpoints
The web isn't just iPhones, iPads and iMacs. There is a huge ecosystem out there of weirdo screen sizes and resolutions, and it's important to support them all. A quick glance at my latest analytics report confirmed this. I don't have a whole lot of visitors, but look at the diversity in screen sizes!

![Cold hard data: a list of screen sizes visitors have been sporting](/images/screensizes.png)

There are quite a few screens in the 300px width range, but there is also a healthy number of 500 to 800px screens, along with screens wider than 1280px. Who knows what devices these may correspond to, but at least we have some sort of idea of what breakpoints we might pick. 

My selection is made up of somewhat arbitrary numbers, but they are not completely random either. First of all, I was trying to be narrower in crowded categories, and a bit wider in the less populated ones. This serves to keep the number of breakpoints down to a manageable level, while serving an image that is close to optimal for most users.

Another concern is that I never want this performance improvement to come at the cost of the quality of the images. That's why I've set my breakpoints just above what most devices need. For instance, I get quite a few visits from devices that are 320 to 375px wide: I've therefore set the lowest breakpoint at 380px because this still gives a good reduction in image size while still making sure that the image looks great.

All in all, I've settled on the following breakpoints:

- 380px
- 550px
- 800px
- 1200px
- 1440px

Screens wider than 1440px can just get the original image, which is usually 1920px wide. Knowing what sizes I wanted to serve, I now had to create them.

*If you're not frankly interested by the nitty-gritty of my implementation, I recommend that you scroll to [the conclusion](#resulting-code-and-considerations).*

## My less-than-trivial implementation 

### A Grunt plugin for resizing images
All these breakpoints make for a whole lot of resizing &mdash; more than I'd ever want to do manually. That's why I've set up a task do do it automatically at build time. As you may know from my [previous post](/travis/), I build and deploy this site using Travis CI. I already have a Grunt task set up to run during the [build process](https://github.com/MaximeKjaer/kjaermaxi.me/blob/master/_scripts/build.sh), so Grunt was a good candidate for managing this additional task.

I used a  plugin called [grunt-responsive-images](https://github.com/andismith/grunt-responsive-images), which runs on GraphicsMagick. That's no real problem though, because I could just add a few lines to my `.travis.yml` to install it:

{% highlight yml linenos %}
...
addons:
  apt:
    packages:
      - graphicsmagick
...
{% endhighlight %}

### Delivering data to both Grunt and Jekyll
I then defined my breakpoints in `_config.yml`; this way, they'd be directly accessible in Jekyll, using the `site.image_breakpoints` variable.

{% highlight yml linenos %}
...
image_breakpoints: # Important that these be in decreasing order!
  - 1440px
  - 1200px
  - 800px
  - 550px
  - 380px
...
{% endhighlight %}

At this point, Jekyll natively knows what our breakpoints are, but Grunt still doesn't, so I got my `Gruntfile.js` to read it from the `_config.yml`:

{% highlight js linenos %}
module.exports = function(grunt) {
    grunt.loadNpmTasks('grunt-responsive-images');

    // Read what image breakpoints have been specified in _config.yml ...
    var breakpoints = grunt.file.readYAML('_config.yml').image_breakpoints;
    
    // ... and store them in the correct format
    var sizes = [];
    for (i = 0; i < breakpoints.length; i++)
        sizes.push({width: breakpoints[i],
                    name: breakpoints[i]});

    grunt.initConfig({
        responsive_images: {
            dist: {
                options: {
                    sizes: sizes,
                    quality: 80
                },
                files: [{
                    expand: true,
                    src: ['images/**.{jpg,gif,png}'],
                    cwd: '_site/',
                    dest: '_site/'
                }]
            }
        }
    });
    grunt.registerTask('build', ['responsive_images:dist']);
};
{% endhighlight %}

With this addition, Grunt and Jekyll should play along nicely. If I want to change the breakpoints, I can just do it once in `_config.yml`. Running `grunt build` now generates the images we need. Cool!

### Fetching the correct image sizes
All that's left to do is to set a few CSS rules to fetch the correct resolution at each given screen width.

Every single post has its own banner image, so the best and easiest solution is to inline the relevant CSS, and inject the correct filenames into it using Jekyll.

This would've been a walk in the park, if it weren't because I had to do a bit of string manipulation. Indeed, I needed to add the image size to the file name, before the file extension. This isn't hard to do *per se*, but it would require a bit of repetitive code if I had to do it for each breakpoint. To avoid just that, I set up the media query in a Jekyll function.

### Jekyll functions?!
Now, if you've used Jekyll before, you might be thinking: "But there's no such thing as a function in Jekyll!", and you'd be totally right. However, since you can pass arguments to an include, it is possible to create a makeshift  function. 

The example below assumes that we have a `background-image` and a `size` variable available, and passes them on to our function:

{% highlight liquid linenos %}{% raw %}
{% for size in site.image_breakpoints %}
    {% include functions/hero-responsive-background.css size=size image=background-image %}
{% endfor %}
{% endraw %}{% endhighlight %}

The function, which I've placed in `_includes/functions/hero-responsive-background.css`, can access the arguments it's been given through the `include` object:

{% highlight liquid linenos %}{% raw %}

{% capture jpg %}-{{ include.size }}.jpg{% endcapture %}
{% capture png %}-{{ include.size }}.png{% endcapture %}
{% capture gif %}-{{ include.size }}.gif{% endcapture %}

{% capture filename %}{{ include.image | replace: '.jpg', jpg | replace: '.png', png | replace '.gif', gif }}{% endcapture %}

@media (max-device-width: {{ include.size }}) {
    .hero {
        background-image: url('{{ filename }}');
    }
}
{% endraw %}{% endhighlight %}


## Resulting code and considerations
The gist of this is that I'm creating a media query that sets the correct resolution of the image for each device width. For this post, for instance, it all works together to create the following:

{% highlight css linenos %}
@media (max-device-width: 1440px) {
    .hero {
        background-image: url('/images/bench-1440px.jpg');
    }
}
@media (max-device-width: 1200px) {
    .hero {
        background-image: url('/images/bench-1200px.jpg');
    }
}

/* et cetera */
{% endhighlight %}


### max-width or max-device-width?
There are actually two variants of the above code. Here, I'm using `max-device-width`, but I could just as well be using `max-width`. There's a slight difference in the way that these two rules apply: with `max-width`, the image size corresponding to the *actual* window width will be downloaded, while `max-device-width` downloads the image corresponding to the *maximal* window width on the user's screen.

The problem with `max-width` is that it'll download a new image if the user resizes their window or rotates their screen; mind you, this is a rather dumb process. If you resize your window to a smaller size, it will redownload a smaller image instead of just keeping the bigger one.

That being said, `max-device-width` isn't flawless either. It downloads the biggest image that we may be required to show. If the user has a window open on half of their screen, and never resizes it to the maximum, we'll have loaded too big of an image.

Downloading an image on the fly during a resize may cause a small lag or flicker. This is not something that I want to happen, hence my decision to go with `max-device-width`. It may sometimes cost me a few kilobytes, but at least I hope to have avoided a small annoyance for the user.


### So is it a viable approach?
The banner image is one of the biggest assets that I'm loading on this page, so dealing with that allowed me to significantly reduce the size of my pages. On this post, for instance, an iPhone will load **40% less data** than a big computer screen.

But I'd like to mention the pitfalls of my approach; once again, this should only be done on actual background images, like the one I have at the top of every post. This is in no way a replacement for images.

The fact that this method can't and shouldn't be applied to `<img>`s is only half the reason why we *need* this new spec for responsive images. The other half is that even when you can apply it, it's not really ideal.

See, what I've done here is to specify absolute rules, with breakpoints that are precise down to the pixel. As rational as my responsive image strategy may be, it just can't account for all the different possible scenarios that someone may load my page under. Bandwidth, latency, data caps and loading priorities, to name a few, are all clues to what image sizes are fit for you. The truth of the matter is that I, as the developer of this site, can at best make a guess on what you'll need. The browser, however, is in a *much better* position to predict what'll be best for you in your current situation.

That's exactly what this new specification is all about. I can now just give the browser a discreet hint of what it could load, and it'll make the decision itself. But right now, no matter how obvious and forced I make my hints, almost half of all browsers will be completely oblivious to them.

![A gif of what I look like giving a subtle hint](http://i.imgur.com/Exh8trU.gif)

Don't get me wrong, I really do look forward to being able to implement `<picture>`, `srcset` and `image-set`. The reality is just that I wouldn't have been able to achieve the same results with them.
