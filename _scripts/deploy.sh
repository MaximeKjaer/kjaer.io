#!/bin/bash
echo "Deploying to remote"
cd _site
git add .
git commit -m "Deploy build #$TRAVIS_BUILD_NUMBER"
git push deploy master
