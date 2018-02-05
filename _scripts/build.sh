#!/bin/bash

# Settings
img_ext="\.png$\|\.gif$\|.jpg$"
zopfli_ext="\.html$\|\.css$\|\.js$\|\.xml$"
gzip_ext="\.gz$"

# Global variable declaration
modfiles=""
modimg=""
modzopfli=""

# Functions
function init {
	echo "Initializing git"
	git init
	git remote add deploy "deploy@kjaermaxi.me:/var/www/kjaermaxi.me"
	git config user.name "Travis CI"
	git config user.email "maxime.kjaer+travisCI@gmail.com"
	echo "Fetching from remote"
	git fetch deploy
	git checkout -b build
}

function build {
	echo "Building..."
	bundle exec jekyll build # Build the site with Jekyll
	grunt build # Build with Grunt; see Gruntfile.js for more details.
	echo "Committing the build"
	git add .
	git commit -q -m "Build #$TRAVIS_BUILD_NUMBER"
}

function compare {
	echo "Comparing this build to the previous one"
	git checkout master
	
	modfiles=$(git diff --name-only master..build | grep -v $gzip_ext)
	modimg=$(grep $img_ext <<< "$modfiles" | tr '\n' ' ') # Not used right now, but this is a TODO.
	modzopfli=$(grep $zopfli_ext <<< "$modfiles" | tr '\n' ' ')
	modfiles=$(echo $modfiles | tr '\n' ' ')

	git merge -X theirs --commit -m "Merge build #$TRAVIS_BUILD_NUMBER" build --allow-unrelated-histories
}

function compress {
	# Compress assets with Zopfli (should always be the last command)
	echo "Compressing the following assets using Zopfli: $modfiles"
	../zopfli/zopfli --i1000 $modzopfli
}

mkdir _site 
cd _site
init
build
compare
compress
cd ..
