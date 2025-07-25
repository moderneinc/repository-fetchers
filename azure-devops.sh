#!/bin/bash

# Show help function
usage() {
    echo "Usage: azure-devops.sh -o <organization> -p <project>"
    echo ""
    echo "Required:"
    echo "  -o  Azure DevOps Organization"
    echo "  -p  Azure DevOps Project"
}

# Parse command-line arguments
while getopts ":uo:p:" opt; do
  case ${opt} in
    o) ORGANIZATION=$OPTARG;;
    p) PROJECT=$OPTARG;;
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

# Fetch repositories and output
az repos list --organization "https://dev.azure.com/$ORGANIZATION" --project "$PROJECT" --output json | jq -r '.[] | [.sshUrl, (.defaultBranch // "main" | sub("refs/heads/"; ""))] | @csv'