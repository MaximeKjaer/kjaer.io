#!/bin/bash
set -x
# Test that all links in our site return a 400, including the favicon
timeout 30s bundle exec htmlproof _site --only-4xx --external_only --check-html --check-favicon --verbose
