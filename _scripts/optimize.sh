#!/bin/bash
set -e

echo "Optimizing build"
npm run optimize

echo "Staging optimized build"
cd _site
git add .
git commit -q -m "Optimize build #$TRAVIS_BUILD_NUMBER"
git push --set-upstream origin staging 
