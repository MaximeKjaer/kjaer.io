#!/bin/bash
set -x

timeout 30s bundle exec htmlproof _site --only-4xx --external_only --disable-external --check-html --check-favicon --href-ignore 'https?:\/\/kjaermaxi\.me'
