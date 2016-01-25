#!/bin/sh
# Test that all links in our site return a 400, including the favicon
# This is a bit complicated, since it raises an error when we add a page. Maybe test internal links locally?
bundle exec htmlproof _site --only-4xx --check-html --check-favicon

# Test that all links in our sitemap.xml and feed.xml return a 400.
bundle exec htmlproof _site --ext .xml --only-4xx
