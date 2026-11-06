#!/usr/bin/env bash
# Serve the site locally with live reload at http://127.0.0.1:4000/
set -e
cd "$(dirname "$0")"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
bundle install --quiet
bundle exec jekyll serve --livereload --unpublished "$@"
