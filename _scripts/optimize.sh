#!/bin/bash

echo "Fetching staged build"
cd _site
git checkout --track deploy/master
git checkout --track deploy/staging
cd ..

echo "Optimizing build"
npm run optimize

echo "Staging optimized build"
cd _site
git add .
git commit -q -m "Optimize build #$TRAVIS_BUILD_NUMBER"
git push
