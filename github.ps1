<#
.SYNOPSIS
    Fetches repository information from a GitHub organization.

.DESCRIPTION
    Queries the GitHub API for all non-archived repositories in an organization
    and outputs CSV data with clone URLs, branches, and metadata.

.PARAMETER Organization
    The GitHub organization name (e.g., "openrewrite")

.EXAMPLE
    .\github.ps1 -Organization openrewrite
    .\github.ps1 openrewrite

.NOTES
    Requires GitHub CLI (gh) to be installed and authenticated.
    Run 'gh auth login' before using this script.
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Organization
)

# Output CSV header
Write-Output '"cloneUrl","branch","origin","path","org"'

# Fetch repositories using GitHub CLI with pagination
$repos = gh api --paginate "orgs/$Organization/repos" | ConvertFrom-Json

# Filter non-archived repos, extract fields, and output CSV
$repos | Where-Object { -not $_.archived } | ForEach-Object {
    $cloneUrl = $_.clone_url
    $branch = $_.default_branch

    # Extract origin (domain) from URL: https://github.com/org/repo -> github.com
    $origin = $cloneUrl -replace '^https://', '' -replace '/.*$', ''

    # Extract path from URL: https://github.com/org/repo.git -> org/repo
    $path = $cloneUrl -replace '^https://[^/]+/', '' -replace '\.git$', ''

    # Output as CSV row
    '"{0}","{1}","{2}","{3}","{4}"' -f $cloneUrl, $branch, $origin, $path, $Organization
} | Sort-Object
