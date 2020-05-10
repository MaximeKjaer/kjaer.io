#!/bin/bash
set -e 

echo "Uploading build to Azure"
az storage blob upload-batch -d \$web -s ./_site
