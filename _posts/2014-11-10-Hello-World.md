---
layout: post
title: Setting up GitHub Pages with Jekyll
---

Huh, well this was easy. Instructions are [here](https://github.com/barryclark/jekyll-now), but in a nutshell, it's all about:

## 1. Fork a preset Jekyll repo

Once you have your own repo, go to the Settings and rename it to `yourGithubUsername.github.io`.


![]({{ site.baseurl }}/images/step1.gif)


## 2. Edit a few settings

You just need to tell Jekyll what your name is, and give it links to whatever you want to link to. To do that, go through the `_config.yml` file, and fill it out a form.

![]({{ site.baseurl }}/images/config.png)

## 3. Write a post

Go to your `_posts` folder and edit the Hello-World file. Don't touch the text between the 3 dashes, but the rest of that Markdown file is your canvas.

Remember to change the date if you want that to be reflected on your blog. To do so, change the name of the Markdown file to fit the following format:

    YEAR-MONTH-DAY-Title_goes_here

![]({{ site.baseurl }}/images/first-post.png)

## 4. Enjoy!

Your Github Page is now available over at `yourGithubUsername.github.io`!!

***

Next step for me: setting up my own theme. Let's go!
