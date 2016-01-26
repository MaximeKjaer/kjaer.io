#!/bin/sh
set -x
if [[ $TRAVIS_BRANCH != 'master' ]] ; then
	# Initialize a new git repo in _site, and push it to our server.
	cd _site
	git init

	git remote add deploy "deploy@kjaermaxi.me:/var/www/kjaermaxi.me"
	git config user.name "Travis CI"
	git config user.email "maxime.kjaer+travisCI@gmail.com"

	git add .
	git commit -m "Deploy"
	git push --force deploy master
else
	echo 'Invalid branch. You can only deploy from master.'
	exit 1
fi
