---
layout: post
title: Class notes
comments: false
---

I'm a Master's student in Computer Science at the [Swiss Federal Institute of Technology (EPFL)](https://epfl.ch/). Throughout my studies, I've always taken quite detailed notes. I find that taking notes during classes helps me concentrate on the content of the lecture, and that perfecting the notes after class is a good way for me to process the information I've just taken in. 

As such, I've accumulated a collection of fairly comprehensive notes for a few courses at EPFL. To me, they're a useful resource for when I want to refresh my memory on a topic that I've seen in the past.

I hope that they may be useful for other people too!

<ul>
{% for post in site.notes %}
    <li>
        <a href="{{ post.url }}">{{ post.title }}</a>
    </li>
{% endfor %}
</ul>
