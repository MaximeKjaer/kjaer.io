#!/bin/bash
set -e 

echo "Fetching staged build"
cd _site
git fetch deploy master
git fetch deploy staging
git checkout --track deploy/master
git checkout --track deploy/staging
git branch
cd ..

echo "Optimizing build"
npm run optimize

echo "Staging optimized build"
cd _site
git add .
git commit -q -m "Optimize build #$TRAVIS_BUILD_NUMBER"
git push
