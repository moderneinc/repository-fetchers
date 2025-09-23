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
            echo ""
            echo "Options:"
            echo "  -g <group>        GitLab group to fetch repositories from"
            echo "  -h <gitlab_domain> GitLab instance URL (default: https://gitlab.com)"
            echo "                    Include any subpath, e.g. https://git.mycompany.com/gitlab"
            echo ""
            echo "Environment variables:"
            echo "  AUTH_TOKEN       Required. Your GitLab personal access token"
            echo ""
            echo "Examples:"
            echo "  # Fetch all accessible projects from gitlab.com"
            echo "  AUTH_TOKEN=your_token ./gitlab.sh"
            echo ""
            echo "  # Fetch projects from a specific group on gitlab.com"
            echo "  AUTH_TOKEN=your_token ./gitlab.sh -g mygroup"
            echo ""
            echo "  # Fetch from self-hosted GitLab"
            echo "  AUTH_TOKEN=your_token ./gitlab.sh -h https://git.mycompany.com"
            echo ""
            echo "  # Fetch from self-hosted GitLab with subpath"
            echo "  AUTH_TOKEN=your_token ./gitlab.sh -h https://git.mycompany.com/gitlab -g team"
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
    base_request_url="$GITLAB_DOMAIN/api/v4/projects?membership=true&simple=true&archived=false"
else
    base_request_url="$GITLAB_DOMAIN/api/v4/groups/$GROUP/projects?include_subgroups=true&simple=true&archived=false"
fi

page=1
per_page=100

echo '"cloneUrl","branch","origin","path","org"'
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
    # Extract the base domain (origin) from GITLAB_DOMAIN for consistency
    gitlab_origin=$(echo "$GITLAB_DOMAIN" | sed -E 's|https?://||')

    echo "$response" | jq -r --arg origin "$gitlab_origin" --arg gitlab_base "$GITLAB_DOMAIN" '(.[] |
        .http_url_to_repo as $url |
        # Extract path by removing the gitlab base URL
        ($url | sub($gitlab_base + "/"; "") | sub("\\.git$"; "")) as $path |
        [.http_url_to_repo, .default_branch, $origin, $path, .namespace.path]) | @csv'

    # Increment page counter
    ((page++))
done
