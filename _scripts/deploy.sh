#!/bin/bash
set -e 

echo "Deploying to remote"
cd _site
git checkout staging
git merge --strategy=ours master # keep staging content, record merge
git checkout master
git merge staging # fast-forward master
git push deploy --delete staging
