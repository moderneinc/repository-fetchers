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
    local next_page=0
    local last_page="false"
    local first_branch=""

    while [ "$last_page" != "true" ] ; do
        local request_url="$bitbucket_url/rest/api/1.0/projects/$project/repos/$repo_slug/branches?start=$next_page&limit=100"

        local response=$(curl --silent -H "Content-Type: application/json" -H "Authorization: Bearer $AUTH_TOKEN" "$request_url")
        if [ $? -ne 0 ]; then
            echo "Error occurred while default branch for $repo_slug." 1>&2
            echo ""
            return
        fi

        # Check if response is valid JSON
        if ! echo "$response" | jq -e '.' >/dev/null 2>&1; then
            echo "Error: Invalid JSON response from Bitbucket API for $repo_slug." 1>&2
            echo "Response saved to: branch-fetch-error-$repo_slug.html" 1>&2
            echo "$response" > "branch-fetch-error-$repo_slug.html"
            echo "" 1>&2
            echo "To debug, run this command manually:" 1>&2
            echo "curl -H 'Content-Type: application/json' -H 'Authorization: Bearer ***' '$request_url'" 1>&2
            echo ""
            return
        fi

        last_page=$(echo "$response" | jq '. | .isLastPage')
        next_page=$(echo "$response" | jq '. | .nextPageStart') 

        for ROW in `echo "$response" | jq -r '.values[] | [.isDefault, .displayId] | @csv | sub("\"";"";"g")'`; do
            IFS=", " read -r is_default branch_name <<< $ROW
            # Store first branch as fallback
            if [ -z "$first_branch" ]; then
                first_branch="$branch_name"
            fi
            if [ "$is_default" = "true" ]; then
                echo $branch_name
                return
            fi
        done
    done

    # If no default branch was found but we have branches, use the first one
    if [ -n "$first_branch" ]; then
        echo "Warning: No default branch found for $repo_slug, using first branch: $first_branch" 1>&2
        echo "$first_branch"
    else
        echo "Failed to find any branches for $repo_slug." 1>&2
        echo ""
    fi
}

function fetch_repos() {
    local next_page=0
    local last_page="false"

    while [ "$last_page" != "true" ] ; do
        local request_url="$bitbucket_url/rest/api/1.0/repos?start=$next_page&limit=100"

        local response=$(curl --silent -H "Content-Type: application/json" -H "Authorization: Bearer $AUTH_TOKEN" "$request_url")
        if [ $? -ne 0 ]; then
            echo "Error occurred while retrieving repository list." 1>&2
            exit 1
        fi

        # Check if response is valid JSON
        if ! echo "$response" | jq -e '.' >/dev/null 2>&1; then
            echo "Error: Invalid JSON response from Bitbucket API. Check your URL and authentication." 1>&2
            echo "Response saved to: repo-fetch-error.html" 1>&2
            echo "$response" > repo-fetch-error.html
            echo "" 1>&2
            echo "To debug, run this command manually:" 1>&2
            echo "curl -H 'Content-Type: application/json' -H 'Authorization: Bearer $AUTH_TOKEN' '$request_url'" 1>&2
            exit 1
        fi

        last_page=$(echo "$response" | jq '. | .isLastPage')
        next_page=$(echo "$response" | jq '. | .nextPageStart') 

        for ROW in `echo "$response" | \
            jq --arg CLONE_PROTOCOL $CLONE_PROTOCOL -r '.values[] | [(.links.clone[] | select(.name == $CLONE_PROTOCOL).href), .slug, .project.key] | @csv | sub("\"";"";"g")'`; do
            IFS=", " read -r clone_url repo_slug project <<< $ROW
            local default_branch=$(fetch_default_branch $repo_slug $project)
            # Extract origin and path from clone_url
            if [[ "$CLONE_PROTOCOL" == "ssh" ]]; then
                # SSH: ssh://git@scm.mycompany.com:7999/proj/repo.git
                origin=$(echo $clone_url | sed -E 's|ssh://[^@]+@([^:]+):?[0-9]*/.*|\1|')
                # Append /stash context if bitbucket_url contains it
                if [[ "$bitbucket_url" == *"/stash"* ]]; then
                    origin="$origin/stash"
                fi
                path=$(echo $clone_url | sed -E 's|ssh://[^/]+/||; s|\.git$||')
            else
                # HTTPS: https://scm.mycompany.com/stash/scm/PROJ/repo.git or http://localhost:7990/scm/PROJ/repo.git
                # Extract just the host:port first
                origin=$(echo $clone_url | sed -E 's|https?://([^/]+)/.*|\1|')
                # Append context path (like /stash) if bitbucket_url contains it
                context_path=$(echo "$bitbucket_url" | sed -E 's|https?://[^/]+||; s|/$||')
                if [[ -n "$context_path" ]]; then
                    origin="$origin$context_path"
                fi
                # Remove /scm from path for HTTPS
                path=$(echo $clone_url | sed -E 's|https?://[^/]+(/[^/]+)?/scm/||; s|https?://[^/]+(/[^/]+)?/||; s|\.git$||')
            fi
            echo $clone_url,$default_branch,$origin,$path
        done
    done
}

echo "cloneUrl,branch,origin,path"
fetch_repos

