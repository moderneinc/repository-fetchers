<#
.SYNOPSIS
    Fetches repository information from Bitbucket Cloud.

.DESCRIPTION
    Queries the Bitbucket Cloud API for all repositories in a workspace
    and outputs CSV data with clone URLs and default branches.

.PARAMETER Workspace
    The Bitbucket Cloud workspace name (required)

.PARAMETER Token
    Bitbucket API token or workspace access token. Can also be set via BITBUCKET_TOKEN environment variable.

.PARAMETER Email
    Atlassian account email. Required for API tokens, omit for workspace access tokens.
    Can also be set via BITBUCKET_EMAIL environment variable.

.EXAMPLE
    .\bitbucket-cloud.ps1 -Workspace myworkspace -Token mytoken -Email me@example.com
    .\bitbucket-cloud.ps1 -Workspace myworkspace -Token myworkspacetoken
    $env:BITBUCKET_TOKEN = "mytoken"
    $env:BITBUCKET_EMAIL = "me@example.com"
    .\bitbucket-cloud.ps1 -Workspace myworkspace

.NOTES
    With -Email, the token is sent as an API token using Basic auth. Without it, the token
    is sent as a workspace access token using Bearer auth.
    Optionally set CLONE_PROTOCOL environment variable to "ssh" for SSH URLs (default is https).
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Workspace,

    [Parameter(Mandatory=$false)]
    [string]$Token,

    [Parameter(Mandatory=$false)]
    [string]$Email
)

# Fall back to environment variables if not provided
if ([string]::IsNullOrEmpty($Token)) {
    $Token = $env:BITBUCKET_TOKEN
}

if ([string]::IsNullOrEmpty($Email)) {
    $Email = $env:BITBUCKET_EMAIL
}

# Validate required parameters
if ([string]::IsNullOrEmpty($Token)) {
    Write-Error "Error: Please provide a token via parameters or environment variables."
    Write-Host "Usage: .\bitbucket-cloud.ps1 -Workspace <workspace> -Token <token> [-Email <email>]"
    Write-Host "Note: Use -Email with API tokens, omit it for workspace access tokens"
    exit 1
}

# Determine clone protocol
$cloneProtocol = if ($env:CLONE_PROTOCOL -eq "ssh") { "ssh" } else { "https" }

# Use Basic auth with email for API tokens, Bearer for workspace access tokens
if (-not [string]::IsNullOrEmpty($Email)) {
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Email}:${Token}"))
    $headers = @{
        Authorization = "Basic $base64Auth"
    }
} else {
    $headers = @{
        Authorization = "Bearer $Token"
    }
}

# Output CSV header
Write-Output "cloneUrl,branch,origin,path"

$nextPage = "https://api.bitbucket.org/2.0/repositories/$Workspace"

while (-not [string]::IsNullOrEmpty($nextPage)) {
    try {
        $response = Invoke-RestMethod -Uri $nextPage -Headers $headers -ErrorAction Stop
    } catch {
        Write-Error "Error from Bitbucket API: $($_.Exception.Message)"
        exit 1
    }

    # Process each repository
    foreach ($repo in $response.values) {
        # Find clone URL by protocol
        $cloneUrl = ($repo.links.clone | Where-Object { $_.name -eq $cloneProtocol }).href

        # Get main branch name
        $branchName = $repo.mainbranch.name

        # Clean credentials from URL (remove username@ from https://username@bitbucket.org/...)
        $cleanUrl = $cloneUrl -replace 'https://[^@]+@', 'https://'

        # Origin is always bitbucket.org for cloud
        $origin = "bitbucket.org"

        # Extract path (workspace/repo) from URL
        if ($cleanUrl -match 'git@') {
            # SSH: git@bitbucket.org:workspace/repository.git
            $path = $cleanUrl -replace '^git@[^:]+:', '' -replace '\.git$', ''
        } else {
            # HTTPS: https://bitbucket.org/workspace/repository.git
            $path = $cleanUrl -replace '^https://[^/]+/', '' -replace '\.git$', ''
        }

        # Output as CSV row
        Write-Output "$cleanUrl,$branchName,$origin,$path"
    }

    # Get next page URL
    $nextPage = $response.next
}
