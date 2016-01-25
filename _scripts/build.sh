#!/bin/sh
# Build the site with Jekyll
bundle exec jekyll build

# Compress assets with Zopfli
zopfli/zopfli --i1000 _site/**/*.html _site/*.html
zopfli/zopfli --i1000 _site/**/*.css _site/*.css
zopfli/zopfli --i1000 _site/**/*.js _site/*.js
zopfli/zopfli --i1000 _site/**/*.xml _site/*.xml
