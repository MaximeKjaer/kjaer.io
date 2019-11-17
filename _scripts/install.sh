#!/bin/bash
set -e 

echo "Importing the SSH deployment key"
openssl aes-256-cbc -K $encrypted_22009518e18d_key -iv $encrypted_22009518e18d_iv -in raindrop-deploy.enc -out raindrop-deploy -d
rm raindrop-deploy.enc
chmod 600 raindrop-deploy
mv raindrop-deploy ~/.ssh/id_rsa

echo "Setting up git"
git config user.name "Travis CI"
git config user.email "maxime.kjaer+travisCI@gmail.com"
git clone --depth 1 --single-branch deploy@kjaer.io:/var/www/kjaer.io/ _site

echo "Installing dependencies"
gem install bundler # Install bundler 2.0, which will be used by Travis in `install` phase
npm install
