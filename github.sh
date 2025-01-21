#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <org>"
  echo "Example: $0 openrewrite"
  exit 1
fi

organization=$1

# JQ
gh api --paginate "orgs/$organization/repos" \
  --jq '["cloneUrl","branch","org"], (.[] | [.clone_url, .default_branch, "'"$organization"'"]) | @csv'
