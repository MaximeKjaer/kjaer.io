---
title: Picking up Sass
description: I've been writing CSS the old-school way for a long time. But I've finally caved in to using Sass. Here's how it has changed the way I write CSS for the better.
image: /images/hero/artist.jpg
fallback-color: "#c6c5b8"
---

I've long been resistant to [Sass](http://sass-lang.com/). To me, it seemed like a complicated and superfluous layer of abstraction that would get in the way of how I usually write my CSS, and perhaps even create bloated, inefficient code &mdash; boy, was I wrong.

As it turns out, Dan Cederholm had the *exact* same fear as I did about having to change the way he writes CSS, but the introduction to [his book](https://abookapart.com/products/sass-for-web-designers) persuaded me to take a look at it:

> But remember, since **the SCSS syntax is a superset of CSS3**, you don't have to change anything about the way you write CSS. Commenting, indenting, or not indenting, all your formatting preferences can remain the same when working in .scss files. Once I realized this, I could dive in without fear.
> 
> [Dan Cederholm, Sass for Web Designers (Chapter 1), 2013](http://alistapart.com/article/why-sass)

Now, I've been using [Jekyll](https://jekyllrb.com/), the static site generator, for close to a year now, even for super simple sites. I really like how I'm able to keep my HTML [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) by using imports, variables and layouts; it's a system that makes any and all edits incredibly easy and sensible. In a sense, Sass is just the equivalent of Jekyll for CSS: I can import CSS from other files, use variables, and inject code into my predefined mixins, just like I can with HTML in Jekyll. And it turns out that my CSS doesn't only get more maintainable, but I've even found that my design as a whole gets better! Here's how Sass has helped me out:

<!-- More -->

## Variables for DRY and systematic code
One of the advantages of variables in any language whatsoever is of course that it can save you some typing while restricting all future changes to one point. For CSS, that means more maintainable and DRY code. As dull as that may sound, it's actually quite agreeable.

But there's more to it than that obvious feature. Just the addition of variables forces me to think within the system that I've created. I have the bad habit of creating a new shade of gray whenever I need one; in a big CSS file, that easily becomes 6 or 7 shades, which just serves to confuse the reader. It may sound dumb, but having a `$light-gray` and a `$dark-gray` variable is something that has made it easier for me to stick to the system that I've created. The same goes for predefined breakpoints, font sizes, line heights, standard transition times... you name it. My design has gained in consistency thanks to Sass.

## Mixins for readable and compatible code
I haven't really explored the world of mixin libraries just yet, but I've already seen their potential just from the ones I've written. Apart from drastically reducing the typing in some places, mixins make the code more readable. Assuming that the mixins and variables are predefined, I think this example will speak for itself; say we want to provide an image in a higher resolution for retina screens. The CSS might look like this:

{% highlight css linenos %}
body {
    background-image: url('/images/example.png');
}

@media (-webkit-min-device-pixel-ratio: 1.5),
       (min--moz-device-pixel-ratio: 1.5),
       (-o-min-device-pixel-r atio: 3 / 2),
       (min-device-pixel-ratio: 1.5),
       (min-resolution: 1.5dppx) {
    body {
        background-image: url('/images/example_@2X.png');
        background-size: 500px 500px;
    }
}
{% endhighlight %}

Meanwhile, the SCSS is just this:

{% highlight scss linenos %}
body {
    background-image: $background;
    @include retina {
        background-image: $background-2x;
        background-size: 500px 500px;
    }
}
{% endhighlight %}

It's much better!

The second way that mixins have proven themselves to be particularly useful is with all the damned vendor prefixes. Using mixins, it's possible to refer to them all using a single line of code. See, this is the kind of abstraction that I was hoping for!

## Imports for modular and performant code
I've always liked to keep different CSS files for different purposes. On this page, for instance, I'd have one for general styling, another for the typography, and a third one for code highlighting. It just makes sense to me to keep these things separate. The only problem is that in some larger projects, I may require part of one stylesheet in another. Now, we know better than to copy-paste the code from one place to another and call it a day; imports can help us with that!

Until [HTTP/2](https://www.youtube.com/watch?v=fJ0C4zN5uOQ) becomes the norm, importing Sass files into eachother using `@import` is pretty much the simplest way to keep things modular on my end while keeping performance on the reader's end in mind. Concatenating everything into one file admittedly breaks caching, but I still find it better than serving multiple files.

### Speaking of performance...
The cool thing about Sass is that it's "just" a preprocessor, meaning that it doesn't really have an impact on the performance. I was afraid that Sass would create ugly CSS, but it turns out that as long you write sensible SCSS, your CSS will look just as fine.

My single gripe is that Sass doesn't group media queries. I really like the way that Dan Cederholm writes his responsive declarations in his book: he uses a mixin that allows him to write declarations like these:

{% highlight scss linenos %}
p {
    line-height: 1.5;
    @include responsive(medium-screens) {
        line-height: 1.4;
    }
    @include responsive(small-screens) {
        line-height: 1.3;
    }
}

article {
    font-size: 1.8rem;
    @include responsive(medium-screens) {
        font-size: 1.6rem;
    }
    @include responsive(small-screens) {
        font-size: 1.4rem;
    }
}
{% endhighlight %}

Sadly, this compiles to the following code:

{% highlight scss linenos %}
p {
  line-height: 1.5;
}

@media only screen and (max-width: 800px) {
  p {
    line-height: 1.4;
  }
}

@media only screen and (max-width: 500px) {
  p {
    line-height: 1.3;
  }
}

article {
  font-size: 1.8rem;
}

@media only screen and (max-width: 800px) {
  article {
    font-size: 1.6rem;
  }
}

@media only screen and (max-width: 500px) {
  article {
    font-size: 1.4rem;
  }
}
{% endhighlight %}

Why Sass won't group the media queries is beyond me. Even though it may not have much of a direct [impact on performance](https://stackoverflow.com/questions/11626174/is-there-an-advantage-in-grouping-css-media-queries-together), it's not exactly elegant, and it does make for bigger files, which does slow down the page as a whole. I'm really hoping that what Cederholm calls “aggregated media query bubbling” will make it into a future release of Sass &mdash; it's not like it's *that* complicated to implement.

## Integrating it into a Jekyll workflow
As I mentioned earlier on, I like working with Jekyll. Luckily for me, Sass and Jekyll play very well together, since Jekyll comes with built-in Sass support. There's not much to configure; here are the options that we can add to the `_config.yml` file:

{% highlight yaml linenos %}
sass:
    style: :compressed # Either :compressed or :expanded
    sass_dir: _sass # This is the default value
{% endhighlight %}

The `sass_dir` is only used by Sass: the files that it contains won't be in the final build; if you want to have a file be compiled, it needs to be somewhere else (I usually have them in a `css` folder placed at the root). But that's as complicated as it gets! Jekyll takes care of the rest when it builds the site.

## Conclusion
I have nothing but good things to say about my transition to Sass. This idea of creating a language that is a superset of another language that the user already knows makes a lot of sense, since it greatly reduces initial reservations and other change aversions. The learning curve is incredibly gentle; you just need to pass the initial bump of giving it a try.

Sass fits nicely into my workflow, was really easy to learn, and makes writing good stylesheets a breeze. In the end, what's not to love?