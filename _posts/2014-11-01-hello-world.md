---
title: Setting up GitHub Pages with Jekyll
description: This is my very first post, in which I show how easy it is to get a first version of a blog up with Github Pages and Jekyll Now.
image: /images/hero/desk.jpg
fallback-color: "#e8e2e3"
---

I've just set up my Jekyll blog using Github Pages! First thoughts? "Huh, well that was easy." Full instructions are [here](https://github.com/barryclark/jekyll-now), but in a nutshell, here's how it goes:

## 1. Fork a preset Jekyll repo

And once you have your own repo, go to the Settings and rename it to `yourGithubUsername.github.io`.

## 2. Edit a few settings

You just need to tell Jekyll what your name is, what your blog will be called, give it links to whatever social media that you want to link to... To do that, go through the `_config.yml` file, and fill it out like a form.

<!-- More -->

## 3. Write a post

Go to your `_posts` folder and edit the Hello-World file. Don't touch the text between the 3 dashes (it *has* to be there), but the rest of that Markdown file is your canvas.

Remember to change the date if you want that to be reflected on your blog. To do so, change the name of the Markdown file to fit the following format:

{% highlight markdown %}
    YEAR-MONTH-DAY-Title_goes_here.md
{% endhighlight %}

## 4. Enjoy!

Your Github Page is now available over at `yourGithubUsername.github.io`!!

***

Next step for me: setting up my own theme. Let's go!
