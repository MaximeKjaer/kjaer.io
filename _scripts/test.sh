#!/bin/bash
set -x

timeout 30s bundle exec htmlproof _site --only-4xx --external_only --check-html --check-favicon
