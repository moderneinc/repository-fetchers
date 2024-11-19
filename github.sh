#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <org>"
  echo "Example: $0 openrewrite"
  exit 1
fi

organization=$1

# JQ
gh repo list "$organization" \
    --json url,defaultBranchRef \
    --jq  '["cloneUrl","branch"], (.[] | [.url, .defaultBranchRef.name]) | @csv'
