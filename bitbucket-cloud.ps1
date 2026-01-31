<#
.SYNOPSIS
    Fetches repository information from Bitbucket Cloud.

.DESCRIPTION
    Queries the Bitbucket Cloud API for all repositories in a workspace
    and outputs CSV data with clone URLs and default branches.

.PARAMETER Workspace
    The Bitbucket Cloud workspace name (required)

.PARAMETER Username
    Bitbucket username. Can also be set via BITBUCKET_USERNAME environment variable.

.PARAMETER AppPassword
    Bitbucket app password. Can also be set via BITBUCKET_APP_PASSWORD environment variable.

.EXAMPLE
    .\bitbucket-cloud.ps1 -Workspace myworkspace -Username myuser -AppPassword mypassword
    $env:BITBUCKET_USERNAME = "myuser"
    $env:BITBUCKET_APP_PASSWORD = "mypassword"
    .\bitbucket-cloud.ps1 -Workspace myworkspace

.NOTES
    Requires Bitbucket app password (not regular password).
    Optionally set CLONE_PROTOCOL environment variable to "ssh" for SSH URLs (default is https).
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Workspace,

    [Parameter(Mandatory=$false)]
    [string]$Username,

    [Parameter(Mandatory=$false)]
    [string]$AppPassword
)

# Fall back to environment variables if not provided
if ([string]::IsNullOrEmpty($Username)) {
    $Username = $env:BITBUCKET_USERNAME
}

if ([string]::IsNullOrEmpty($AppPassword)) {
    $AppPassword = $env:BITBUCKET_APP_PASSWORD
}

# Validate required parameters
if ([string]::IsNullOrEmpty($Username) -or [string]::IsNullOrEmpty($AppPassword)) {
    Write-Error "Error: Please provide username and app password via parameters or environment variables."
    Write-Host "Usage: .\bitbucket-cloud.ps1 -Workspace <workspace> -Username <username> -AppPassword <password>"
    exit 1
}

# Determine clone protocol
$cloneProtocol = if ($env:CLONE_PROTOCOL -eq "ssh") { "ssh" } else { "https" }

# Set up Basic auth header
$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${AppPassword}"))
$headers = @{
    Authorization = "Basic $base64Auth"
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

    # Get next page URL (remove embedded credentials)
    $nextPage = $response.next
    if (-not [string]::IsNullOrEmpty($nextPage)) {
        $nextPage = $nextPage -replace "${Username}@", ''
    }
}
