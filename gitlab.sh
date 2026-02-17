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


if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed." >&2
    echo "Install it from https://jqlang.github.io/jq/download/ or use gitlab.ps1 on Windows." >&2
    exit 1
fi

if [[ -z $AUTH_TOKEN ]]; then
    echo "Please set the AUTH_TOKEN environment variable."
    exit 1
fi

if [ -z "$CLONE_PROTOCOL" ] || [ "$CLONE_PROTOCOL" != "ssh" ]; then
    CLONE_PROTOCOL=https
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

    # Check if response is valid JSON
    if ! echo "$response" | jq -e '.' >/dev/null 2>&1; then
        echo "Error: Invalid JSON response from GitLab API." >&2
        echo "Response: $response" >&2
        exit 1
    fi

    # Check if response is an error (object with message/error field instead of array)
    if echo "$response" | jq -e 'type == "object" and (.message or .error)' >/dev/null 2>&1; then
        error_msg=$(echo "$response" | jq -r '.message // .error // "Unknown error"')
        echo "Error from GitLab API: $error_msg" >&2
        exit 1
    fi

    # Check if the response is empty, if so, break the loop
    if [[ $(echo "$response" | jq '. | length') -eq 0 ]]; then
        break
    fi

    # Process and output data
    echo "$response" | jq -r --arg origin "${GITLAB_DOMAIN#*//}" --arg protocol "$CLONE_PROTOCOL" '(.[] | [(if $protocol == "ssh" then .ssh_url_to_repo else .http_url_to_repo end), .default_branch, $origin, .path_with_namespace, .namespace.path]) | @csv'

    # Increment page counter
    ((page++))
done
