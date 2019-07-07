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
git clone --depth 1 deploy@kjaer.io:/var/www/kjaer.io/ _site

echo "Installing dependencies"
if [[ -v TRAVIS_RUBY_VERSION ]]; then
    gem update --system --silent --quiet
    gem install bundler --silent --quiet
fi
if [[ -v TRAVIS_NODE_VERSION ]]; then
    npm install
fi
