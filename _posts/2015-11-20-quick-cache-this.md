---
title: Quick, cache this! Everything you need to know about web cache
description: This blog post serves as a primer on web cache HTTP headers. I'll also show the reasoning behind a good caching strategy, and how to implement it with Nginx.
image: /images/hero/letter.jpg
fallback-color: "#ead3d1"
---

In my previous post on [Web Performance 2.0](/web-performance-2.0/), I wrote:

> Cache, compression and CDNs are still relevant, and should be used.

In retrospect, this was a bit of a hypocritical sentence, since I was only doing one out of the three on this site, namely compression. Today, we'll be taking a look at web caching. It's not too hard to put it into place, but it *is* easy to mess up, so I'll try to proceed with care.

I run a fully static site hosted on a DigitalOcean droplet with Nginx, so luckily for me, I just have to mess with some config files. However, like any other good university student, I studied the theory long and arduously before I could ever dream of touching those files.

All right, that's a lie, I totally just dived headlong into my `nginx.conf` and googled stuff as I went. Still, let's be smarter than I was, and take a minute to look at the theory.

## The theory
There are a number of HTTP headers that give the browser instructions on how to cache a website. As always when you're working with the Web, for historical reasons, it's far from simple or elegant. There are quite a few headers to set, and they often overlap. Here are the cache headers that you'll probably have to consider:

<!-- More -->

- `ETag`
- `If-None-Match`
- `Last-Modified`
- `If-Modified-Since`
- `Cache-Control`
- `Expires`
- `Date`

Yes, this *is* a lot. Still, let's dive into it.

### Cache validation: Entity Tags & "Last Modified" dates
An ETag is a validation token, or, simply put, a sort of version number that is stuck on the file. This is useful when a browser wants to check whether its cached copy of a file still is up to date (this check is called a "cache validation"). Instead of asking for the whole file again, it can just ask if the server still is serving the same file as last time. If so, there's no need to redownload it.

Technically, this is done by giving each file a code. Received files will come with a header such as `ETag: "564bb8e6-4d4b"`. This information is saved, and the next time we request the same file, the browser sends along the header `If-None-Match: "564bb8e6-4d4b"`. The web server checks that this corresponds to the file it's got. If we have a match, the server will respond with [304 Not Modified](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#3xx_Redirection). Otherwise, it'll send [200 OK](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#2xx_Success) along with the new version of the file (and its new ETag header).

It's important to note that there exists an alternative to `ETag/If-None-Match` with overlapping functionality: `Last-Modified/If-Modified-Since`. The validation token is a date instead of a hash, but for all intents and purposes, it's pretty much identical. They can be used interchangeably, but using both is a bit redundant. If you are creating a page dynamically, it may make more sense to use `ETags`, as you can hash the data to see if it's the same as last time. For static files, it's perhaps easier to use `Last-Modified`. However, Nginx abstracts the concern away from us, so let's disregard this problem here.

ETags are an important cache mechanism, as they introduce big optimizations. A roundtrip to the server is still necessary, but it can save us the trouble of redownloading a file we already have. They come into play if `Cache-Control` has been set to `no-cache` or if the cached file is older than the specified `max-age`. If you are unfamiliar with web cache, this may still sound like some technical mumbo jumbo, so let's clear it up.

### Cache freshness with Cache-Control & Expiration dates
`Cache-Control` is an HTTP response header that defines the caching rules for a file. It can be set to a comma-separated selection of the following values:

- `public` or `private` define who should be able to cache the file.
    + `public`: The file is cacheable by the browser and by all intermediaries (such as CDNs).
    + `private`: The file is only cacheable by the browser.
- `no-cache` or `no-store` define stricter caching rules
    + `no-cache`: Cache the file, but don't use it without checking with the server that it hasn't changed.
    + `no-store`: Nobody should cache *anything*.
- `max-age`: The number of seconds for which we can use the cached file. After this, we will have to check for it again (although we may not *have* to redownload it; see [cache validation](#cache-validation-entity-tags--last-modified-dates)).

Combining these settings can be useful in a number of configurations:

- `public` and a given `max-age` is useful for purely static content.
- `private` and a given `max-age` is for information that isn't necessarily personal, but is user-specific.
- `no-cache` is great when it's critical to have the latest version of a file (for live feeds, or content based on random numbers, for instance).
- `no-store` is mainly for private, personal data that shouldn't be cached (for security reasons).

Once again, there is another header with overlapping functionality: `Expires`. While `Cache-Control: max-age=600` will set a 10 minute timeout, `Expires: Fri, 20 Nov 2015 23:56:13 GMT` will just time out at the set date. When using `Expires`, we also add a `Date` header so we know what time the server thinks it currently is.

Also good to know: `max-age` overrides `Expires`. See, I told you that there would be inelegant overlap!

## Choosing a strategy
With all of this in mind, how can we devise an optimal caching strategy? Our caching settings will depend on how often a file is updated, and on how important it is that the user has the latest version. Obviously, as files are different in nature, we will need to use different caching settings for each kind of resource.

Here is the reasoning behind *my* caching strategy.

### HTML
The HTML has to be fresh. I can't set a long cache time, because visitors would risk missing out on new content, so we need to validate the cache every once in a while. The question that remains is how often to do this.

Should I validate it every time, which implies using `Cache-Control: no-cache`? Or should I have the cache expire shortly, which means using `Cache-Control: max-age=XXX`?

Sadly, the reality is that I only write 5 or 6 posts a year, and that doesn't really justify validating the cache for every request. The content is just very unlikely to be updated between two page refreshes. This is why I've decided to cache the HTML for the duration of a session, which I've (arbitrarily, and rather optimistically) set to **10 minutes**. If the content of a page is updated while someone is viewing the page, then they'll just be able to see it next time &mdash; I find this to be a decent trade-off for the performance gains.

It's super important to have a low max age on cached HTML, because this allows you to make mistakes in other areas. Say that I messed up, and gave too high of a max age to a CSS file. Since my cached HTML often is revalidated, I can just change the name of the CSS file, which will prompt the browser to treat it as a new item and download it.

This is why a lot of people add a so-called fingerprint to CSS, JS and images during their build process. For example, `style.css` would be served under the name `style.4ba39f2.css` before a modification, and automatically be renamed `style.63fa213.css` after a change. This way, we get the best of both worlds: caching and quick updates.

### Images
I don't usually modify my images, except if I've been able to further compress it. If the user already has a slightly bigger image in cache, there's no real need to download another version that might be a few KB smaller. So for images, I can just use the **longest possible max age**. In case I ever need to actually change it, I'll use a different filename.

### CSS & JS
I don't serve any JavaScript files on this site, but cache-wise, it should fall into the same category as CSS. I update it every once in a while, but little will be lost if the user doesn't get the absolute latest version. I should be able to get away with a max age that is a bit longer, like **a week** or so. I only want to build using Jekyll, and it can't add fingerprints to files, so this is "good enough" of an alternative.

## Let's get it into practice!
Phew, the hard part is over! Now, let's kick back and see how we can get Nginx to apply what we've decided.

First, let's make sure that we at least have Nginx 1.7.3. Before this version, we couldn't have ETags on gzip compressed content. This is some pretty important functionality, so let's just check:

{% highlight bash linenos %}
$ nginx -v
nginx version: nginx/1.8.0
{% endhighlight %}

If you don't have the necessary version, you can just quickly update:

{% highlight sh linenos %}
$ sudo add-apt-repository ppa:nginx/stable
$ sudo apt-get update
$ sudo apt-get install nginx
{% endhighlight %}

Now we'll get into the thick of it. You'll have to modify your `server` block in `/etc/nginx/nginx.conf` (or possibly another file, depending on your configuration).

To set a `max-age`, we use the `expires` [keyword](http://nginx.org/en/docs/http/ngx_http_headers_module.html). This adds both a `Cache-Control` and an `Expires` header, which is a bit redundant, but oh well. We're not setting `Cache-Control: public`, since it's implicit with `Cache-Control: max-age=XXX`. Otherwise, there's not much left for us to do, since Nginx is nice enough to enable `ETag` and `Last-Modified` by default. The server block of our configuration files ends up looking like this:

{% highlight nginx linenos %}
server {
    # HTML and XML
    location ~* \.(?:html|xml)$ {
        add_header Content-Language "en";
        expires 10m;
    }

    # Media: images, icons, video, audio
    location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm)$ {
        access_log off;
        expires max;
    }

    # CSS and Javascript
    location ~* \.(?:css|js)$ {
        access_log off;
        expires 1d;
    }
}
{% endhighlight %}

To apply our changes, don't forget to run:

{% highlight sh linenos %}
$ nginx -s reload
{% endhighlight %}

That should be about it. It's almost disappointingly simple, right? But I did warn you in the beginning: this is not hard to do, it's just easy to mess up, which is why the theoretical part is so important. You really need to be able to explain your choices, and hopefully, this post will have taught you that. Now go out and apply what you've learned. Go out and make the Web just a little bit faster.
