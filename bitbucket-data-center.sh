#!/bin/bash


if [ -z "$1" ]; then
    echo "Usage: $0 <bitbucket_url>"
    echo "Example: $0 https://my-bitbucket.com/stash"
    exit 1
fi

bitbucket_url=$1
auth_header=""

if [ -n "$AUTH_TOKEN" ]; then
    auth_header="Authorization: Bearer $AUTH_TOKEN"
fi

ALL_REPOS=$(curl -s -X GET -H "Content-Type: application/json" -H "$auth_header" "$bitbucket_url/rest/api/1.0/repos"| jq -r '.values[] | [.slug, .project.key, (.links.clone[] | select(.name == "http").href)] | @csv')
if [ $? -ne 0 ]; then
    echo "Error occurred while retrieving repository list."
    exit 1
fi

echo "cloneUrl,branch"
for REPO in $ALL_REPOS; do
    IFS=',' read -r repo project cloneUrl <<< "$REPO"
    repo="${repo//\"/}"
    project="${project//\"/}"
    cloneUrl="${cloneUrl//\"/}"
    branch=$(curl -s -X GET -H "Content-Type: application/json" -H "$auth_header" "$bitbucket_url/rest/api/latest/projects/$project/repos/$repo/default-branch" | jq -r '.displayId')

    echo "$cloneUrl,$branch"
done