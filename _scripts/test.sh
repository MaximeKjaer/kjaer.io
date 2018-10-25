#!/bin/bash

echo "Proofing the HTML"
timeout 240s bundle exec htmlproofer ./_site --check-html --check-favicon --allow-hash-href --external_only --only-4xx --http-status-ignore 429
