#!/bin/bash
set -e

echo "Resetting staging"
git checkout master
git branch -D staging || true
git checkout -b staging

echo "Building"
npm run build

echo "Staging build"
cd _site
git add .
git commit -m "Build #$TRAVIS_BUILD_NUMBER"
git push --force
