# [KjaerMaxi.me](http://kjaermaxi.me/)

My personal page - built using [Jekyll](http://jekyllrb.com/) & elbow grease.

## Syntax of a post:

    ---
    layout: post
    title: A sample post
    description: Showing the syntax of a post.
    image: splash-image.jpg
    link: http://link-to-something-interesting.com/
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
    
    <!--- Separator -->

    This text won't be shown in the preview, as it comes after the Separator tag.
    
    ## Quotes
    
    > "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras in consectetur augue. Sed quis efficitur mauris. Suspendisse potenti. Duis maximus consequat leo, eget placerat eros venenatis id. Cras a sem turpis. Quisque porta sollicitudin magna, mattis luctus risus pulvinar malesuada. Fusce posuere mattis convallis. Aliquam sit amet dictum metus, quis accumsan libero."  
    > *-- Cicero*

    ## Images
    
    ![Image title](http://link-to-image.com/image.jpeg)
    
    ![Image title](/images/local-image.jpeg) // This is better, by the way.
    
    ## Ending a post
    
    No particular syntax is needed to end a post.

## To-do

- Better links in the footer.
- Better IDs for my `#cd-placeholder1` sections.
- Add tags to posts (will fit right under "Written on ...") **only possible after self-hosting, since it requires a plugin - so consider a DigitalOcean plan**
- Try out a few other SEO tricks (just enough to get the site to actually show when googling my name).