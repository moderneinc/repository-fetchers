<#
.SYNOPSIS
    Fetches repository information from GitLab.

.DESCRIPTION
    Queries the GitLab API for all projects in a group (or all projects visible
    to the user) and outputs CSV data with clone URLs, branches, and metadata.

.PARAMETER Group
    Optional GitLab group name. If not specified, returns the projects you are a
    member of (see -IncludeAllRepos).

.PARAMETER GitLabDomain
    Optional GitLab domain URL. Defaults to https://gitlab.com

.PARAMETER IncludeAllRepos
    Only applies when -Group is not specified. By default the query is limited to
    projects you hold a role on (membership=true). Pass this switch to instead
    return every project visible to your token, which on a large instance
    includes all public and internal projects and can be a very large result set.

.EXAMPLE
    $env:AUTH_TOKEN = "your-token"
    .\gitlab.ps1
    .\gitlab.ps1 -Group mygroup
    .\gitlab.ps1 -Group mygroup -GitLabDomain https://gitlab.mycompany.com
    .\gitlab.ps1 -IncludeAllRepos

.NOTES
    Requires AUTH_TOKEN environment variable to be set with a GitLab personal access token.
    Optionally set CLONE_PROTOCOL environment variable to "ssh" for SSH URLs (default is https).
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Group,

    [Parameter(Mandatory=$false)]
    [string]$GitLabDomain = "https://gitlab.com",

    [Parameter(Mandatory=$false)]
    [switch]$IncludeAllRepos
)

# Validate AUTH_TOKEN
if ([string]::IsNullOrEmpty($env:AUTH_TOKEN)) {
    Write-Error "Please set the AUTH_TOKEN environment variable."
    exit 1
}

# Determine clone protocol
$cloneProtocol = if ($env:CLONE_PROTOCOL -eq "ssh") { "ssh" } else { "https" }

# Build base request URL
if ([string]::IsNullOrEmpty($Group)) {
    # Limit to projects the user is a member of unless -IncludeAllRepos was passed
    $membership = if ($IncludeAllRepos) { "" } else { "membership=true&" }
    $baseUrl = "$GitLabDomain/api/v4/projects?${membership}simple=true&archived=false"
} else {
    $baseUrl = "$GitLabDomain/api/v4/groups/$Group/projects?include_subgroups=true&simple=true&archived=false"
}

# Extract origin from domain (remove https:// prefix)
$origin = $GitLabDomain -replace '^https?://', ''

# Set up headers
$headers = @{
    Authorization = "Bearer $env:AUTH_TOKEN"
}

# Output CSV header
Write-Output '"cloneUrl","branch","origin","path"'

$page = 1
$perPage = 100

while ($true) {
    $requestUrl = "$baseUrl&page=$page&per_page=$perPage"

    try {
        $response = Invoke-RestMethod -Uri $requestUrl -Headers $headers -ErrorAction Stop
    } catch {
        Write-Error "Error from GitLab API: $($_.Exception.Message)"
        exit 1
    }

    # Check if response is empty (no more results)
    if ($null -eq $response -or $response.Count -eq 0) {
        break
    }

    # Process and output data
    foreach ($project in $response) {
        # Select clone URL based on protocol
        if ($cloneProtocol -eq "ssh") {
            $cloneUrl = $project.ssh_url_to_repo
        } else {
            $cloneUrl = $project.http_url_to_repo
        }

        $branch = $project.default_branch
        $path = $project.path_with_namespace

        # Output as CSV row
        Write-Output ('"{0}","{1}","{2}","{3}"' -f $cloneUrl, $branch, $origin, $path)
    }

    $page++
}
