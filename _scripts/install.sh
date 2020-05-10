#!/bin/bash
set -e 

echo "Installing Azure CLI"
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install apt-transport-https azure-cli
az login -u $AZ_LOGIN_NAME -p $AZ_PASSWORD --service-principal --tenant $AZ_TENANT > /dev/null 2>&1

echo "Installing dependencies"
gem install bundler # Install bundler 2.0, which will be used by Travis in `install` phase
npm install
