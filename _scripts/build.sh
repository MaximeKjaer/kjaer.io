#!/bin/bash

echo "Building"
npm run build

echo "Staging build"
cd _site
git checkout -b staging
git add .
git commit -q -m "Build #$TRAVIS_BUILD_NUMBER"
git push deploy
