#!/bin/bash


if [ -z "$1" ]; then
    echo "Usage: $0 <bitbucket_url>"
    echo "Example: $0 https://my-bitbucket.com/stash"
    exit 1
fi

bitbucket_url=$1
auth_header=""

if [ -z "$AUTH_TOKEN" ]; then
    echo "Please set the AUTH_TOKEN environment variable."
    exit 1
fi

page=1
limit=100
echo '"cloneUrl","branch","org"'
while :; do
    # Construct the request URL with pagination parameters
    request_url="$bitbucket_url/rest/api/1.0/repos?page=$page&limit=100"

    # Fetch the data
    response=$(curl --silent -H "Content-Type: application/json" -H "Authorization: Bearer $AUTH_TOKEN" "$request_url")

    if [ $? -ne 0 ]; then
        echo "Error occurred while retrieving repository list."
        exit 1
    fi

    # Check if the response is empty, if so, break the loop
    if [[ $(echo "$response" | jq '. | length') -eq 0 ]]; then
        break
    fi

    # Process and output data
    echo "$response" | jq -r '.values[] | [.slug, .project.key, (.links.clone[] | select(.name == "http").href)] | @csv'

    # Increment page counter
    ((page++))
done
