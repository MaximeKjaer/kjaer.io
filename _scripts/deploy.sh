#!/bin/bash
set -e 

echo "Uploading build to Azure"
az storage blob upload-batch --account-name $AZURE_STORAGE_ACCOUNT --source ./_site --destination \$web --output none
