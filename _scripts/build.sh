#!/bin/bash
set -e

echo "Resetting staging"
cd _site
git checkout master
git branch -D staging || true
git checkout -b staging
cd ..

echo "Building"
bundle exec jekyll build

echo "Staging build"
cd _site
git add .
git commit -m "Build #$TRAVIS_BUILD_NUMBER"
git push --force --set-upstream origin staging
cd ..
