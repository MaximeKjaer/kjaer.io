#!/bin/bash

echo "Building"
npm run build

echo "Staging build"
cd _site
git fetch deploy staging
git checkout -b staging
git add .
git commit -q -m "Build #$TRAVIS_BUILD_NUMBER"
git push -u deploy staging
