#!/bin/bash

echo "Fetching staged build"
cd _site
git checkout --track deploy/staging
cd ..

echo "Test"
travis_wait 15 npm run test
