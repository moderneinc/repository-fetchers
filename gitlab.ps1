<#
.SYNOPSIS
    Fetches repository information from GitLab.

.DESCRIPTION
    Queries the GitLab API for all projects in a group (or all user's projects)
    and outputs CSV data with clone URLs, branches, and metadata.

.PARAMETER Group
    Optional GitLab group name. If not specified, returns all user's projects.

.PARAMETER GitLabDomain
    Optional GitLab domain URL. Defaults to https://gitlab.com

.EXAMPLE
    $env:AUTH_TOKEN = "your-token"
    .\gitlab.ps1
    .\gitlab.ps1 -Group mygroup
    .\gitlab.ps1 -Group mygroup -GitLabDomain https://gitlab.mycompany.com

.NOTES
    Requires AUTH_TOKEN environment variable to be set with a GitLab personal access token.
    Optionally set CLONE_PROTOCOL environment variable to "ssh" for SSH URLs (default is https).
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Group,

    [Parameter(Mandatory=$false)]
    [string]$GitLabDomain = "https://gitlab.com"
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
    $baseUrl = "$GitLabDomain/api/v4/projects?membership=true&simple=true&archived=false"
} else {
    $encodedGroup = $Group -replace '/', '%2F'
    $baseUrl = "$GitLabDomain/api/v4/groups/$encodedGroup/projects?include_subgroups=true&simple=true&archived=false"
}

# Extract origin from domain (remove https:// prefix)
$origin = $GitLabDomain -replace '^https?://', ''

# Set up headers
$headers = @{
    Authorization = "Bearer $env:AUTH_TOKEN"
}

# Output CSV header
Write-Output '"cloneUrl","branch","origin","path","org"'

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
        $org = $project.namespace.path

        # Output as CSV row
        Write-Output ('"{0}","{1}","{2}","{3}","{4}"' -f $cloneUrl, $branch, $origin, $path, $org)
    }

    $page++
}
