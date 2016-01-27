#!/bin/bash
set -x
# Test that all links in our site return a 400, including the favicon
# This is a bit complicated, since it raises an error when we add a page. Maybe test internal links locally?
timeout 20s bundle exec htmlproof _site --only-4xx --check-html --check-favicon --checks-to-ignore "LinkCheck"

# Test that all links in our sitemap.xml and feed.xml return a 400.
timeout 20s bundle exec htmlproof _site --ext .xml --only-4xx --checks-to-ignore "LinkCheck"