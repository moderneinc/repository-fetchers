#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <org>"
  echo "Example: $0 openrewrite"
  exit 1
fi

organization=$1

echo "\"cloneUrl\",\"branch\",\"origin\",\"path\",\"org\""
gh api --paginate "orgs/$organization/repos" --jq '.[] | select(.archived == false) |
  .clone_url as $url |
  ($url | sub("https://"; "") | sub("/"; " ") | split(" ")[0]) as $origin |
  ($url | sub("https://[^/]+/"; "") | sub("\\.git$"; "")) as $path |
  [$url, .default_branch, $origin, $path, "'"$organization"'"] | @csv' | sort
#gh api --paginate "orgs/$organization/repos" --jq '.[] | select(.archived == false) |
#  .ssh_url as $url |
#  ($url | sub("git@"; "") | sub(":"; " ") | split(" ")[0]) as $origin |
#  ($url | sub("git@[^:]+:"; "") | sub("\\.git$"; "")) as $path |
#  [$url, .default_branch, $origin, $path, "'"$organization"'"] | @csv' | sort
