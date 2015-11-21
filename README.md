# [KjaerMaxi.me](http://kjaermaxi.me/)

[![Build Status](https://travis-ci.org/MaximeKjaer/kjaermaxi.me.svg?branch=travis-test)](https://travis-ci.org/MaximeKjaer/kjaermaxi.me)

My personal page - built using [Jekyll](http://jekyllrb.com/) & elbow grease.

## Syntax of a post:

    ---
    layout: post
    title: A sample post
    image: splash-image.jpg
    description: This is a sample post showing how everything that you can do with this Jekyll site.
    published: false # Defaults to true.
    comments: false # Defaults to true.
    ---

    Using the YAML Front Matter (everything above this sentence) is mandatory. Filling out the post and title fields is more than highly recommended.

    This text will be the post's body, and will also be shown on the front page's preview.
    
    ## Code
    
    It is possible to insert code:
    
    {% highlight python %}
    def hello():
        print("Hello World!")
    {% endhighlight %}
    
    As of right now, line numbers don't work because of a bug in Rouge.

    ## Separator
    
    This text will be shown in the preview, as it comes before the Separator tag.
    
    <!--- Separator -->

    This text won't be shown in the preview, as it comes after the Separator tag.
    
    ## Quotes
    
    > Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras in consectetur augue. Sed quis efficitur mauris. Suspendisse potenti. Duis maximus consequat leo, eget placerat eros venenatis id. Cras a sem turpis. Quisque porta sollicitudin magna, mattis luctus risus pulvinar malesuada. Fusce posuere mattis convallis. Aliquam sit amet dictum metus, quis accumsan libero.

    ## Images
    
    ![Image title](http://link-to-image.com/image.jpeg)
    ![Image title](/images/local-image.jpeg)
