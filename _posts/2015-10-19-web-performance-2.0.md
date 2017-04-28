---
title: Web Performance 2.0 
description: After a long lull, a surge of new web performance tools are coming out. From HTTP/2 to resource hints, the landscape of performance is changing.
image: /images/hero/train.jpg
fallback-color: "#d1c8c8"
edited: true
---

The web is changing. We've been calling it [Web 1.0](https://en.wikipedia.org/wiki/Web_2.0#.22Web_1.0.22), then [2.0](https://en.wikipedia.org/wiki/Web_2.0), [3.0](https://en.wikipedia.org/wiki/Semantic_Web#Web_3.0), [4.0](http://bigthink.com/big-think-tv/web-40-the-ultra-intelligent-electronic-agent-is-coming), [5.0](https://flatworldbusiness.wordpress.com/flat-education/previously/web-1-0-vs-web-2-0-vs-web-3-0-a-bird-eye-on-the-definition/)... Yet to this day, no one really knows what any of the above is supposed to mean! To me, arbitrarily assigning version numbers to the web is sensationalism at best, it isn't based on anything tangible. And yet, I'm going to talk about something that I actually believe in: Web Performance 2.0.

A couple of week ago, I went to [Paris Web](https://www.paris-web.fr/), a conference about the Web, held in (you guessed it!) Paris. I heard lots of talks, and coming back from it, there's a lot of food for thought. One talk stuck with me, though: in his [WebPerf 2.0](https://stefounet.github.io/webperf2.0/#/) talk, [Stephane Rios](https://twitter.com/stefounet) called for a new, metaphorical version 2.0 of Web performance.

## Why call it 2.0?
Unlike "Web X.0", the name "Web Performance 2.0" isn't *completely* unfounded. It still sounds a bit buzzword-y to me, but I get the idea. In this case, the version number is a bit more coherent, since it is also that of the [latest version of HTTP](https://http2.github.io/). The [HTTP protocol](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol) is so indistinguishably tied to how we do performance that it's almost acceptable to say "Web Performance 2.0" instead of "HTTP/2 Web Performance". This new version of HTTP will introduce major changes in how we deal with Web performance, so the number 2.0 is actually based on something concrete.

<!-- More -->

## Why do we need 2.0?
First and foremost, we need this new HTTP specification because we can do better than its 20-year-old predecessor. At scale, upgrading will save huge amounts of time and resources, and thus electricity and money. Great.

But as a technical person myself, I'm more interested in what it changes for us people behind the scenes. For years, it's been considered best practice to use semi-dirty hacks like [domain sharding, spriting, inlining and concatenation](http://http2-explained.haxx.se/content/en/part3.html). Each and every one of those has some technical drawbacks (usually involving cache), but they also make for a lot of work! Why is it that *I* need to deal with this? Performance shouldn't need to be an *additional* task or service, it should be implemented at the *core* of the Web. We need standards and specifications, not a collection of homebrew hacks; it's high time we graduate from those.

As a general rule, optimization should happen at as low an abstraction level as possible, so that I personally need to take care of as few things as possible, and concentrate on the task at hand. 


## Finally, a correct solution
This why I think that we may finally be solving the problem of Web performance correctly with HTTP/2: it fixes the issues at the correct abstraction level, not the one above. When working with Web Performance 1.0, everyone had to apply their own homemade fixes and patches to circumvent the flaws of the underlying technology. Now, the optimizations are baked in at the technology's level; simply put, the new version shifts some responsibility from the individual to the technological stack. That benefits both the website maker and, perhaps more importantly so, the Web as a whole!

That being said, I am well aware of the fact that HTTP/2 is no panacea. Obviously, developers shouldn't behave recklessly and rely on it to somehow magically solve everything. 

[Cache](https://en.wikipedia.org/wiki/Web_cache), [compression](https://en.wikipedia.org/wiki/HTTP_compression) and [CDN](https://en.wikipedia.org/wiki/Content_delivery_network)s are still relevant, and *should* be used. If you want more advanced control, we have a surge of new tools made specifically for the job (see [async, defer](http://www.growingwiththeweb.com/2014/02/async-vs-defer-attributes.html), [resource hints](https://www.w3.org/TR/resource-hints/), [preload](https://w3c.github.io/preload/), [service workers](https://docs.google.com/presentation/d/1GNLc4oRZzazq4Th8vsH3v5GekAbKWsxIXHbNtQFFG-c/present?slide=id.p19)...). Additionally, there may still be [dirty hacks](https://www.w3.org/Bugs/Public/show_bug.cgi?id=27303) that may make a website *feel* faster; some of them may be worth implementing. But please, don't go overboard with these, like we have in the past. With Web Performance 2.0, you shouldn't have to.
