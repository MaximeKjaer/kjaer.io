#!/bin/bash
set -x
# Build the site with Jekyll
bundle exec jekyll build

# Compress assets with Zopfli
zopfli/zopfli --i1000 --verbose _site**/*.html  _site**/*.css _site**/*.js  _site**/*.xml
