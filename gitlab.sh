#!/bin/bash

while getopts ":g:h:" opt; do
    case ${opt} in
        g )
            GROUP=$OPTARG
            ;;
        h )
            GITLAB_DOMAIN=$OPTARG
            ;;
        \? )
            echo "Usage: gitlab.sh [-g <group>] [-h <gitlab_domain>]"
            exit 1
            ;;
    esac
done


if [[ -z $AUTH_TOKEN ]]; then
    echo "Please set the AUTH_TOKEN environment variable."
    exit 1
fi

# default GITLAB_DOMAIN to gitlab.com
GITLAB_DOMAIN=${GITLAB_DOMAIN:-https://gitlab.com}

if [[ -z $GROUP ]]; then
    base_request_url="$GITLAB_DOMAIN/api/v4/projects?membership=true&simple=true"
else
    base_request_url="$GITLAB_DOMAIN/api/v4/groups/$GROUP/projects?include_subgroups=true&simple=true"
fi

page=1
per_page=100

echo '"cloneUrl","branch","org"'
while :; do
    # Construct the request URL with pagination parameters
    request_url="${base_request_url}&page=${page}&per_page=${per_page}"

    # Fetch the data
    response=$(curl --silent --header "Authorization: Bearer $AUTH_TOKEN" "$request_url")

    # Check if the response is empty, if so, break the loop
    if [[ $(echo "$response" | jq '. | length') -eq 0 ]]; then
        break
    fi

    # Process and output data
    echo "$response" | jq -r '(.[] | [.http_url_to_repo, .default_branch, .namespace.path]) | @csv'

    # Increment page counter
    ((page++))
done
