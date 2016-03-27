#!/bin/bash

echo "Importing the SSH deployment key"
openssl aes-256-cbc -K $encrypted_22009518e18d_key -iv $encrypted_22009518e18d_iv -in raindrop-deploy.enc -out raindrop-deploy -d
rm raindrop-deploy.enc
chmod 600 raindrop-deploy
mv raindrop-deploy ~/.ssh/id_rsa

echo "Installing zopfli"
git clone https://code.google.com/p/zopfli/
cd zopfli
make
chmod +x zopfli
cd ..

echo "Installing npm dependencies"
npm install
