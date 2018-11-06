#!/bin/bash

echo "Proofing the HTML"
bundle exec htmlproofer ./_site --check-html --check-favicon  --allow-hash-href --check_opengraph
timeout --preserve-status 180s bundle exec htmlproofer ./_site --external_only --only-4xx --http-status-ignore 429
