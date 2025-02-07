#!/bin/bash

usage() {
  echo "Usage: $0 -u <username> -p <password> <workspace>"
  exit 1
}

# Parse command-line arguments
while getopts ":u:p:" opt; do
  case ${opt} in
    u) username=$OPTARG;;
    p) app_password=$OPTARG;;
    *) usage;;
  esac
done
shift $((OPTIND -1))

# Set workspace from positional argument
workspace=$1

# Check if username and app_password are provided via command line or environment variables
if [ -z "$username" ]; then
    username=$BITBUCKET_USERNAME
fi

if [ -z "$app_password" ]; then
    app_password=$BITBUCKET_APP_PASSWORD
fi

if [ -z "$username" -o -z "$app_password" -o -z "$workspace" ]; then
    echo "Error: Please provide username, password, and workspace." >&2
    usage
fi

echo "cloneUrl,branch"

next_page="https://api.bitbucket.org/2.0/repositories/$workspace"

while [ "$next_page" ]; do
  response=$(curl -s -u "$username:$app_password" "$next_page")

  # Extract repository data and append to CSV file
  echo $response | jq -r '
    .values[] |
    (.links.clone[] | select(.name=="https") | .href) as $cloneUrl |
    .mainbranch.name as $branchName |
    "\($cloneUrl),\($branchName)"' |
  while IFS=, read -r cloneUrl branchName; do
    cleanUrl=$(echo "$cloneUrl" | sed -E 's|https://[^@]+@|https://|')
    echo "$cleanUrl,$branchName"
  done

  next_page=$(echo $response | sed -e "s:${username}@::g" | jq -r '.next // empty')
done
