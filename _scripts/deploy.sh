#!/bin/bash
set -e 

echo "Committing build to master"
cd _site
git add .
git commit -m "Build #$TRAVIS_BUILD_NUMBER"

echo "Deploying to remote"
git push -u origin master
cd ..
