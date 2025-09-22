#!/bin/bash

usage() {
  echo "Usage: $0 -t <token> <workspace>"
  echo "Alternative: Set BITBUCKET_TOKEN environment variable"
  exit 1
}

# Parse command-line arguments
while getopts ":t:" opt; do
  case ${opt} in
    t) token=$OPTARG;;
    *) usage;;
  esac
done
shift $((OPTIND -1))

# Set workspace from positional argument
workspace=$1

# Check if token is provided via command line or environment variable
if [ -z "$token" ]; then
    token=$BITBUCKET_TOKEN
fi

if [ -z "$token" -o -z "$workspace" ]; then
    echo "Error: Please provide token and workspace." >&2
    usage
fi

if [ -z "$CLONE_PROTOCOL" -o "$CLONE_PROTOCOL" != "ssh" ]; then
    CLONE_PROTOCOL=https
fi

echo "cloneUrl,branch"

next_page="https://api.bitbucket.org/2.0/repositories/$workspace"

while [ "$next_page" ]; do
  response=$(curl -s -H "Authorization: Bearer $token" "$next_page")

  # Extract repository data and append to CSV file
  echo $response | jq --arg CLONE_PROTOCOL $CLONE_PROTOCOL -r '
    .values[] |
    (.links.clone[] | select(.name == $CLONE_PROTOCOL) | .href) as $cloneUrl |
    .mainbranch.name as $branchName |
    "\($cloneUrl),\($branchName)"' |
  while IFS=, read -r cloneUrl branchName; do
    cleanUrl=$(echo "$cloneUrl" | sed -E 's|https://[^@]+@|https://|')
    echo "$cleanUrl,$branchName"
  done

  next_page=$(echo $response | jq -r '.next // empty')
done
