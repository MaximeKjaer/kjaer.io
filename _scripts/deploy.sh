#!/bin/bash
if [ $TRAVIS_BRANCH == 'master' ] ; then
	echo "Deploying to remote"
	cd _site
	git add .
	git commit -m "Deploy build #$TRAVIS_BUILD_NUMBER"
	git push deploy master
else
	echo "Not deploying, since this branch isn't master."
fi
