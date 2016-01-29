#!/bin/bash
set -x
# Build the site with Jekyll
bundle exec jekyll build

# Build with Grunt; see Gruntfile.js for more details.
grunt build

# Compress assets with Zopfli (should always be the last command)
zopfli/zopfli --i1000 _site/**/*.html _site/*.html  _site/**/*.css _site/*.css _site/**/*.js _site/*.js _site/**/*.xml _site/*.xml
