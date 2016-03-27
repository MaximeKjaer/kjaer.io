#!/bin/bash
if [ $TRAVIS_BRANCH == 'master' ] ; then
	echo "Deploying to remote"
	git push deploy master
else
	echo "Not deploying, since this branch isn't master."
fi
