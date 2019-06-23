#!/bin/bash
set -e 

echo "Building"
npm run build

echo "Staging build"
cd _site
git add .
git commit -m "Build #$TRAVIS_BUILD_NUMBER"
git push --force --set-upstream deploy staging
