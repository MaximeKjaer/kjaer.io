#!/bin/bash

# Settings
img_ext="\.png$\|\.gif$\|.jpg$"
zopfli_ext="\.html$\|\.css$\|\.js$\|\.xml$"
gzip_ext="\.gz$"

# Global variable declaration
modfiles=""
modimg=""
modzopfli=""

echo "Initializing git"
mkdir _site
cd _site
git init
git remote add deploy "deploy@kjaermaxi.me:/var/www/kjaermaxi.me"
git config user.name "Travis CI"
git config user.email "maxime.kjaer+travisCI@gmail.com"

echo "Fetching from remote"
git fetch deploy

echo "Building"
git checkout -b build
cd ..
bundle exec jekyll build # Build the site with Jekyll
grunt build # Build with Grunt; see Gruntfile.js for more details.

echo "Committing the build"
cd _site
git add .
git commit -q -m "Build #$TRAVIS_BUILD_NUMBER"

echo "Comparing this build to the previous one"
git checkout master
modfiles=$(git diff --name-only master..build | grep -v $gzip_ext)
modimg=$(grep $img_ext <<< "$modfiles" | tr '\n' ' ') # Not used right now, but this is a TODO.
modzopfli=$(grep $zopfli_ext <<< "$modfiles" | tr '\n' ' ')
modfiles=$(echo $modfiles | tr '\n' ' ')

echo "Merging build into master"
git merge --allow-unrelated-histories -X theirs --commit -m "Merge build #$TRAVIS_BUILD_NUMBER" build
# 'git merge -X theirs' does not remove deleted files in build, so we must do it manually:
deleted=$(git diff --name-only master..build | grep -v $gzip_ext | tr '\n' ' ') # deleted1.html deleted2.html
deleted_gz=$(sed -e 's/ \|$/.gz /g' <<< $deleted) # deleted1.html.gz deleted2.html.gz
git rm --ignore-unmatch $deleted $deleted_gz

echo "Compressing the following assets using Zopfli: $modzopfli"
../zopfli/zopfli --i100 $modzopfli
cd ..
