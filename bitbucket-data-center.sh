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

if [ -z "$CLONE_PROTOCOL" -o "$CLONE_PROTOCOL" != "ssh" ]; then
    CLONE_PROTOCOL=http
fi

nextPage=1
echo '"cloneUrl","branch","org"'
while :; do
    # Construct the request URL with pagination parameters
    request_url="$bitbucket_url/rest/api/1.0/repos?start=$nextPage&limit=100"

    # Fetch the data
    response=$(curl --silent -H "Content-Type: application/json" -H "Authorization: Bearer $AUTH_TOKEN" "$request_url")

    if [ $? -ne 0 ]; then
        echo "Error occurred while retrieving repository list."
        exit 1
    fi

    # Process and output data
    if [ "$CLONE_PROTOCOL" = "http" ]; then
        echo "$response" | jq -r '.values[] | [(.links.clone[] | select(.name == "http").href), .slug, .project.key] | @csv'
    else 
        echo "$response" | jq -r '.values[] | [(.links.clone[] | select(.name == "ssh").href), .slug, .project.key] | @csv'
    fi


    isLastPage=$(echo "$response" | jq '. | .isLastPage') 
    if [ "$isLastPage" = "true" ]; then
        exit
    fi

    nextPage=$(echo "$response" | jq '. | .nextPageStart') 
done
