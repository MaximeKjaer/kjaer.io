#!/bin/bash
set -e 

echo "Importing the SSH deployment key"
openssl aes-256-cbc -K $encrypted_22009518e18d_key -iv $encrypted_22009518e18d_iv -in raindrop-deploy.enc -out raindrop-deploy -d
rm raindrop-deploy.enc
chmod 600 raindrop-deploy
mv raindrop-deploy ~/.ssh/id_rsa

echo "Setting up git"
mkdir _site
cd _site
git init
git remote add deploy "deploy@kjaer.io:/var/www/kjaer.io"
git config user.name "Travis CI"
git config user.email "maxime.kjaer+travisCI@gmail.com"
cd ..

echo "Installing dependencies"
gem update --system --silent --quiet
gem install bundler --silent --quiet
npm install
