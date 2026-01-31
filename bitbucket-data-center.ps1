<#
.SYNOPSIS
    Fetches repository information from Bitbucket Data Center.

.DESCRIPTION
    Queries the Bitbucket Data Center API for all repositories
    and outputs CSV data with clone URLs and default branches.

.PARAMETER BitbucketUrl
    The base URL of the Bitbucket Data Center instance (e.g., https://my-bitbucket.com/stash)

.EXAMPLE
    $env:AUTH_TOKEN = "your-token"
    .\bitbucket-data-center.ps1 -BitbucketUrl https://my-bitbucket.com/stash

.NOTES
    Requires AUTH_TOKEN environment variable to be set with a Bitbucket personal access token.
    Optionally set CLONE_PROTOCOL environment variable to "ssh" for SSH URLs (default is http).
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$BitbucketUrl
)

# Validate AUTH_TOKEN
if ([string]::IsNullOrEmpty($env:AUTH_TOKEN)) {
    Write-Error "Please set the AUTH_TOKEN environment variable."
    exit 1
}

# Determine clone protocol
$cloneProtocol = if ($env:CLONE_PROTOCOL -eq "ssh") { "ssh" } else { "http" }

# Set up headers
$headers = @{
    "Content-Type" = "application/json"
    Authorization = "Bearer $env:AUTH_TOKEN"
}

function Get-DefaultBranch {
    param(
        [string]$RepoSlug,
        [string]$Project
    )

    $nextPage = 0
    $lastPage = $false
    $firstBranch = $null

    while (-not $lastPage) {
        $requestUrl = "$BitbucketUrl/rest/api/1.0/projects/$Project/repos/$RepoSlug/branches?start=$nextPage&limit=100"

        try {
            $response = Invoke-RestMethod -Uri $requestUrl -Headers $headers -ErrorAction Stop
        } catch {
            Write-Warning "Error occurred while fetching default branch for $RepoSlug`: $($_.Exception.Message)"
            return ""
        }

        $lastPage = $response.isLastPage
        $nextPage = $response.nextPageStart

        foreach ($branch in $response.values) {
            # Store first branch as fallback
            if ($null -eq $firstBranch) {
                $firstBranch = $branch.displayId
            }

            if ($branch.isDefault -eq $true) {
                return $branch.displayId
            }
        }
    }

    # If no default branch was found but we have branches, use the first one
    if (-not [string]::IsNullOrEmpty($firstBranch)) {
        Write-Warning "No default branch found for $RepoSlug, using first branch: $firstBranch"
        return $firstBranch
    } else {
        Write-Warning "Failed to find any branches for $RepoSlug."
        return ""
    }
}

function Get-Repositories {
    $nextPage = 0
    $lastPage = $false

    while (-not $lastPage) {
        $requestUrl = "$BitbucketUrl/rest/api/1.0/repos?start=$nextPage&limit=100"

        try {
            $response = Invoke-RestMethod -Uri $requestUrl -Headers $headers -ErrorAction Stop
        } catch {
            Write-Error "Error occurred while retrieving repository list: $($_.Exception.Message)"
            exit 1
        }

        $lastPage = $response.isLastPage
        $nextPage = $response.nextPageStart

        foreach ($repo in $response.values) {
            # Find clone URL by protocol
            $cloneUrl = ($repo.links.clone | Where-Object { $_.name -eq $cloneProtocol }).href

            $repoSlug = $repo.slug
            $project = $repo.project.key

            # Fetch default branch for this repo
            $defaultBranch = Get-DefaultBranch -RepoSlug $repoSlug -Project $project

            # Extract path (project/repo)
            $path = "$project/$repoSlug"

            # Output as CSV row
            Write-Output "$cloneUrl,$defaultBranch,$origin,$path"
        }
    }
}

# Extract origin from BitbucketUrl (domain + optional context path like /stash)
$origin = $BitbucketUrl -replace '^https?://', '' -replace '/scm.*$', '' -replace '/$', ''

# Output CSV header
Write-Output "cloneUrl,branch,origin,path"

# Fetch all repositories
Get-Repositories
