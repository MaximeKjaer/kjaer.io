#!/bin/bash
set -e 

echo "Fetching staged build"
cd _site
git fetch deploy staging
git checkout --track deploy/staging
cd ..

echo "Test"
npm run test
