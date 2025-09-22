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

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI (az) is not installed. Please install it first." >&2
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" >&2
    exit 1
fi

# Check if azure-devops extension is installed and install if needed
if ! az extension list --query "[?name=='azure-devops'].name" -o tsv 2>/dev/null | grep -q "azure-devops"; then
    echo "Installing azure-devops extension..." >&2
    az extension add --name azure-devops -y >&2
fi

# Configure extension to allow preview versions without prompting
az config set extension.dynamic_install_allow_preview=false 2>/dev/null

# Output CSV header
echo "cloneUrl,branch,origin,path"

# Fetch repositories using TSV output and process manually
az repos list --organization "https://dev.azure.com/$ORGANIZATION" --project "$PROJECT" --output tsv --query '[].{sshUrl: sshUrl, defaultBranch: defaultBranch, remoteUrl: remoteUrl}' | while IFS=$'\t' read -r ssh_url default_branch remoteUrl; do
    # Handle cases where defaultBranch might be empty or null
    if [[ -z "$default_branch" || "$default_branch" == "null" ]]; then
        branch="main"
    else
        # Remove refs/heads/ prefix if present
        branch="${default_branch#refs/heads/}"
    fi

    # Extract origin and path to be consistent across SSH and HTTPS
    # Origin is always dev.azure.com/org for consistency
    origin="dev.azure.com/$ORGANIZATION"

    # Path is project/_git/repo for consistency
    if [[ -z "$USE_HTTPS" ]]; then
      # SSH: git@ssh.dev.azure.com:v3/org/project/repo
      # Extract repo name from SSH URL
      repo_name=$(echo "$ssh_url" | sed -E 's|.*v3/[^/]+/[^/]+/||')
      path="$PROJECT/_git/$repo_name"
      echo "\"$ssh_url\",\"$branch\",\"$origin\",\"$path\""
    else
      # HTTPS: https://dev.azure.com/org/project/_git/repo
      # Remove username@ prefix from URL
      clean_url=$(echo "$remoteUrl" | sed -E 's|https://[^@]+@|https://|')
      # Extract path after organization
      path=$(echo "$clean_url" | sed -E "s|https://dev.azure.com/$ORGANIZATION/||")
      echo "\"$clean_url\",\"$branch\",\"$origin\",\"$path\""
    fi
done