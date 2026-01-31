<#
.SYNOPSIS
    Fetches repository information from Azure DevOps.

.DESCRIPTION
    Queries the Azure DevOps API for all repositories in a project
    and outputs CSV data with clone URLs and default branches.

.PARAMETER Organization
    The Azure DevOps organization name

.PARAMETER Project
    The Azure DevOps project name

.PARAMETER UseHttps
    Use HTTPS URLs instead of SSH URLs (default is SSH)

.EXAMPLE
    .\azure-devops.ps1 -Organization myorg -Project myproject
    .\azure-devops.ps1 -Organization myorg -Project myproject -UseHttps

.NOTES
    Requires Azure CLI (az) to be installed and authenticated.
    Run 'az login' and 'az extension add --name azure-devops' before using this script.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Organization,

    [Parameter(Mandatory=$true)]
    [string]$Project,

    [switch]$UseHttps
)

# Output CSV header
Write-Output "cloneUrl,branch,origin,path"

# Fetch repositories using Azure CLI
$repos = az repos list --organization "https://dev.azure.com/$Organization" --project $Project --output json | ConvertFrom-Json

# Origin is always dev.azure.com/org for consistency
$origin = "dev.azure.com/$Organization"

foreach ($repo in $repos) {
    # Select URL based on protocol preference
    if ($UseHttps) {
        $cloneUrl = $repo.remoteUrl
    } else {
        $cloneUrl = $repo.sshUrl
    }

    # Handle defaultBranch - might be empty, null, or have refs/heads/ prefix
    $branch = $repo.defaultBranch
    if ([string]::IsNullOrEmpty($branch) -or $branch -eq "null") {
        $branch = "main"
    } else {
        # Remove refs/heads/ prefix if present
        $branch = $branch -replace '^refs/heads/', ''
    }

    # Path is project/_git/repo for consistency
    $path = "$Project/_git/$($repo.name)"

    # Output as CSV row
    Write-Output ('"{0}","{1}","{2}","{3}"' -f $cloneUrl, $branch, $origin, $path)
}
