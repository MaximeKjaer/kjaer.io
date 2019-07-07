#!/bin/bash
set -e 

echo "Merging build to master"
cd _site
git checkout master
git merge --squash -m "Deploy build #$TRAVIS_BUILD_NUMBER" --allow-unrelated-histories -X theirs staging
git commit -m "Deploy build #$TRAVIS_BUILD_NUMBER"

echo "Deploying to remote"
git push -u origin master
git push origin --delete staging
cd ..
