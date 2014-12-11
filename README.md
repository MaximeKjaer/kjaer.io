# [KjaerMaxi.me](http://kjaermaxi.me/)

My personal page - built using [Jekyll](http://jekyllrb.com/) & elbow grease.

## Syntax of a post:

    ---
    layout: post
    title: A sample post
    description: Showing the syntax of a post.
    link: http://link-to-something-interesting.com/
    ---

    Using the YAML Front Matter (everything above this sentence) is mandatory.

        layout: post

    and

        title: Some Title

    are highly recommended.

    This text will be the post's body, and will also be shown on the front page's preview.

    <!--- Separator -->

    This text won't be shown in the preview, as it comes after the Separator comment.

    No particular syntay is needed to end a post.

## To-do

- Minify CSS and JS.
- Make a better footer.
- Better IDs for my `#cd-placeholder1` sections.
- Add tags to posts (will fit right under "Written on ...") **only possible after self-hosting, since it requires a plugin - so consider a DigitalOcean plan**
- Try out a few other SEO tricks (just enough to get the site to actually show when googling my name).
- Add an `image:` field to the YAML Front Matter in posts.
