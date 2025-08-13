#!/bin/bash

# Show help function
usage() {
    echo "Usage: azure-devops.sh -o <organization> -p <project>"
    echo ""
    echo "Required:"
    echo "  -o  Azure DevOps Organization"
    echo "  -p  Azure DevOps Project"
    echo "Optional:"
    echo "  -h  to use HTTPS URLs instead of SSH URLs"
}

# Parse command-line arguments
while getopts ":o:p:h" opt; do
  case ${opt} in
    o) ORGANIZATION=$OPTARG;;
    p) PROJECT=$OPTARG;;
    h) USE_HTTPS=true;;
    *) usage;;
  esac
done
shift $((OPTIND -1))

# Validate required parameters
if [[ -z "$ORGANIZATION" ]]; then
    echo "Error: Organization is required (-o)"
    usage
    exit 1
fi

if [[ -z "$PROJECT" ]]; then
    echo "Error: Project is required (-p)"
    usage
    exit 1
fi

# Output CSV header
echo "cloneUrl,branch"

# Fetch repositories using TSV output and process manually
az repos list --organization "https://dev.azure.com/$ORGANIZATION" --project "$PROJECT" --output tsv --query '[].{sshUrl: sshUrl, defaultBranch: defaultBranch, remoteUrl: remoteUrl}' | while IFS=$'\t' read -r ssh_url default_branch remoteUrl; do
    # Handle cases where defaultBranch might be empty or null
    if [[ -z "$default_branch" || "$default_branch" == "null" ]]; then
        branch="main"
    else
        # Remove refs/heads/ prefix if present
        branch="${default_branch#refs/heads/}"
    fi

    # Output in CSV format with proper quoting
    if [[ -z "$USE_HTTPS" ]]; then
      echo "\"$ssh_url\",\"$branch\""
    else
      echo "\"$remoteUrl\",\"$branch\""
    fi
done