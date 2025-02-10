#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <bitbucket_url>"
    echo "Example: $0 https://my-bitbucket.com/stash"
    exit 1
fi

bitbucket_url=$1

if [ -z "$AUTH_TOKEN" ]; then
    echo "Please set the AUTH_TOKEN environment variable."
    exit 1
fi

if [ -z "$CLONE_PROTOCOL" -o "$CLONE_PROTOCOL" != "ssh" ]; then
    CLONE_PROTOCOL=http
fi

function fetch_default_branch() {
    local repo_slug=$1
    local project=$2
    local next_page=1

    while :; do
        local request_url="$bitbucket_url/rest/api/1.0/projects/$project/repos/$repo_slug/branches?start=$next_page&limit=100"
        local response=$(curl --silent -H "Content-Type: application/json" -H "Authorization: Bearer $AUTH_TOKEN" "$request_url")
        if [ $? -ne 0 ]; then
            echo "Error occurred while default branch for $repo_slug." 1>&2
            echo ""
            return
        fi

        local last_page=$(echo "$response" | jq '. | .isLastPage')
        local next_page=$(echo "$response" | jq '. | .nextPageStart') 

        for ROW in `echo "$response" | jq -r '.values[] | [.isDefault, .displayId] | @csv | sub("\"";"";"g")'`; do
            IFS=", " read -r is_default branch_name <<< $ROW
            if [ "$is_default" ]; then
                echo $branch_name
                return
            fi
        done

        if [ "$last_page" = "true" ]; then
            echo "Failed to find default branch for $repo_slug." 1>&2
            echo ""
            return
        fi
    done
}

function fetch_repos() {
    local next_page=1
    while :; do
        local request_url="$bitbucket_url/rest/api/1.0/repos?start=$next_page&limit=100"

        local response=$(curl --silent -H "Content-Type: application/json" -H "Authorization: Bearer $AUTH_TOKEN" "$request_url")

        if [ $? -ne 0 ]; then
            echo "Error occurred while retrieving repository list." 1>&2
            exit 1
        fi

        local last_page=$(echo "$response" | jq '. | .isLastPage')
        local next_page=$(echo "$response" | jq '. | .nextPageStart') 

        for ROW in `echo "$response" | \
            jq --arg CLONE_PROTOCOL $CLONE_PROTOCOL -r '.values[] | [(.links.clone[] | select(.name == $CLONE_PROTOCOL).href), .slug, .project.key] | @csv | sub("\"";"";"g")'`; do
            IFS=", " read -r clone_url repo_slug project <<< $ROW
            local default_branch=$(fetch_default_branch $repo_slug $project)
            echo $clone_url,$default_branch
        done

        if [ "$last_page" = "true" ]; then
            exit
        fi
    done
}

echo "cloneUrl,branch"
fetch_repos

