## Repository Fetchers

This directory contains scripts that query a source code manager (SCM) to create a CSV file that contains a list of repositories and their details. This list of repositories can then be used for easy cloning with the [Moderne CLI](https://docs.moderne.io/user-documentation/moderne-cli/getting-started/cli-intro) or it can be used to help you create an [Organizations service](https://docs.moderne.io/administrator-documentation/moderne-platform/how-to-guides/org-service/).

The expected output looks similar to:

```csv
cloneUrl,branch,origin,path
https://github.com/openrewrite/rewrite-spring,main,github.com,openrewrite/rewrite-spring
https://github.com/openrewrite/rewrite-recipe-markdown-generator,main,github.com,openrewrite/rewrite-recipe-markdown-generator
https://github.com/openrewrite/rewrite-docs,master,github.com,openrewrite/rewrite-docs
https://github.com/openrewrite/rewrite,main,github.com,openrewrite/rewrite
https://github.com/openrewrite/rewrite-python,main,github.com,openrewrite/rewrite-python
https://github.com/openrewrite/rewrite-migrate-java,main,github.com,openrewrite/rewrite-migrate-java
https://github.com/openrewrite/rewrite-recommendations,main,github.com,openrewrite/rewrite-recommendations
https://github.com/openrewrite/rewrite-testing-frameworks,main,github.com,openrewrite/rewrite-testing-frameworks
https://github.com/openrewrite/rewrite-gradle-tooling-model,main,github.com,openrewrite/rewrite-gradle-tooling-model
https://github.com/openrewrite/rewrite-recipe-bom,main,github.com,openrewrite/rewrite-recipe-bom
```

## Platform Support

Each SCM has two script versions:
- **Bash scripts** (`.sh`) for Linux and macOS - require `jq` for JSON parsing
- **PowerShell scripts** (`.ps1`) for Windows - use native PowerShell JSON parsing

## Supported SCMs
* [GitHub](#github)
* [Bitbucket Data Center](#bitbucket-data-center)
* [Bitbucket Cloud](#bitbucket-cloud)
* [GitLab](#gitlab)
* [Azure DevOps](#azure-devops)

Below are the details of each script along with examples of how to invoke them and their required/optional arguments.

### GitHub

This script fetches all repositories from a GitHub organization.

#### Usage
```sh
./github.sh <organization_name>
```

#### Description
This script fetches all repositories from the specified GitHub organization.

##### Prerequisites:
1. You must also have the [GitHub CLI](https://cli.github.com/) installed.
2. You must either have run [`gh auth login`](https://cli.github.com/manual/gh_auth_login) or set the `GITHUB_TOKEN` environment variable for authentication.

(**Note**: if you use a GitHub installation rather than `github.com` you will have to `gh auth login --hostname github.mycompany.com`)

##### Token requirements
The script lists repositories with `GET /orgs/{org}/repos`, so it only returns the repositories the authenticated user can see in the organization.

- **`gh auth login`**: the default scopes are sufficient.
- **Classic personal access token**: needs the `repo` scope. Without it only public repositories are returned.
- **Fine-grained personal access token**: set the resource owner to the organization and grant access to all repositories (or the ones you want listed). The `Metadata: Read-only` repository permission that GitHub adds automatically is enough to list them; add `Contents: Read-only` if you also clone with this token. Your organization may need to approve the token before it can be used.

If the organization enforces SAML single sign-on, the token must also be authorized for that organization.

#### Example

**Linux/macOS (Bash):**
```sh
./github.sh my-organization
```

**Windows (PowerShell):**
```powershell
.\github.ps1 -Organization my-organization
```


### Bitbucket Data Center

This script fetches all repositories from a Bitbucket Data Center instance.

#### Usage
```sh
./bitbucket-data-center.sh <bitbucket_url>
```

#### Description
This script fetches all repositories from the specified Bitbucket Data Center URL. The `AUTH_TOKEN` environment variable must be set for authentication.

##### Token requirements
`AUTH_TOKEN` must be an HTTP access token with **Repository read** permission. A token never exceeds the permissions of its owner, so a personal token lists only the repositories that user can read. Project and repository HTTP access tokens also work, but only list the repositories in their own project or repository.

#### Example

**Linux/macOS (Bash):**
```sh
AUTH_TOKEN=YOUR_TOKEN ./bitbucket-data-center.sh https://my-bitbucket.com/stash
```

**Windows (PowerShell):**
```powershell
$env:AUTH_TOKEN = "YOUR_TOKEN"
.\bitbucket-data-center.ps1 -BitbucketUrl https://my-bitbucket.com/stash
```

#### Optional Environment Variables
- `CLONE_PROTOCOL`: Set to `ssh` to use SSH URLs instead of HTTP. Defaults to `http`.

### Bitbucket Cloud

This script fetches all repositories from a Bitbucket Cloud workspace.

#### Usage
```sh
./bitbucket-cloud.sh -t <token> [-e <email>] <workspace>
```

#### Description
This script fetches all repositories from the specified Bitbucket Cloud workspace. It accepts either kind of Bitbucket Cloud token:

- **API token**: created under your Atlassian account settings with the `read:repository:bitbucket` scope. Pass it with the email address of your Atlassian account (`-e`), and it is sent using Basic auth.
- **Workspace access token**: created in the workspace settings with the `Repositories: Read` permission. Omit the email, and it is sent as a Bearer token.

| Option | Environment variable | Description                                                  |
|--------|----------------------|--------------------------------------------------------------|
| `-t`   | `BITBUCKET_TOKEN`    | API token or workspace access token (required)               |
| `-e`   | `BITBUCKET_EMAIL`    | Atlassian account email, required only for API tokens        |

#### Example

**Linux/macOS (Bash):**
```sh
# API token
./bitbucket-cloud.sh -t YOUR_API_TOKEN -e you@example.com myworkspace
# Workspace access token
./bitbucket-cloud.sh -t YOUR_WORKSPACE_TOKEN myworkspace
# Or using environment variables:
BITBUCKET_TOKEN=YOUR_API_TOKEN BITBUCKET_EMAIL=you@example.com ./bitbucket-cloud.sh myworkspace
```

**Windows (PowerShell):**
```powershell
# API token
.\bitbucket-cloud.ps1 -Workspace myworkspace -Token YOUR_API_TOKEN -Email you@example.com
# Workspace access token
.\bitbucket-cloud.ps1 -Workspace myworkspace -Token YOUR_WORKSPACE_TOKEN
# Or using environment variables:
$env:BITBUCKET_TOKEN = "YOUR_API_TOKEN"
$env:BITBUCKET_EMAIL = "you@example.com"
.\bitbucket-cloud.ps1 -Workspace myworkspace
```

#### Optional Environment Variables
- `CLONE_PROTOCOL`: Set to `ssh` to use SSH URLs instead of HTTPS. Defaults to `https`.

### GitLab

This script fetches all repositories from a GitLab instance or a specific group within a GitLab instance.

#### Usage
```sh
./gitlab.sh [-g <group>] [-h <gitlab_domain>] [-a]
```

#### Description
This script fetches all repositories from a GitLab instance or a specific group within a GitLab instance. The `AUTH_TOKEN` environment variable must be set for authentication. The `-g` option specifies a group to fetch repositories from. The `-h` option specifies the GitLab domain (defaults to `https://gitlab.com` if not provided). The `-a` option includes all repos (see below).

##### Token requirements
`AUTH_TOKEN` can be a personal access token, a group access token, or a project access token. It needs:

- **Scope**: `read_api`. The script only calls the REST API, so `read_repository` alone is not enough, and the broader `api` scope is not needed.
- **Role**: at least **Reporter** on the projects you want listed. Guests can see a private project, but GitLab omits its default branch from the API response, so the `branch` column comes back empty. Reporter is also the minimum role needed to clone the repositories afterwards.

A group access token only sees the projects in its group and subgroups, and a project access token only sees its own project.

**Note**: If your GitLab instance is installed at a subpath (e.g., `https://git.mycompany.com/gitlab/`), include the full URL with the subpath in the `-h` option.

**Note**: When no group is specified, the query is limited to projects you are a member of (`membership=true`). If that returns fewer repositories than you expect — for example because your access comes from project visibility, admin rights, or a group/project access token rather than a membership role — pass `-a` (PowerShell: `-IncludeAllRepos`) to return every project visible to your token instead. On a large instance that includes all public and internal projects and can be a very large result set, so prefer scoping with `-g` where you can.

#### Examples
To fetch the repositories you are a member of from gitlab.com:
```sh
AUTH_TOKEN=YOUR_TOKEN ./gitlab.sh
```

To fetch every repository visible to your token:
```sh
AUTH_TOKEN=YOUR_TOKEN ./gitlab.sh -a
```

To fetch all repositories from a specific group on gitlab.com:
```sh
AUTH_TOKEN=YOUR_TOKEN ./gitlab.sh -g my-group
```

To fetch from a self-hosted GitLab instance:
```sh
AUTH_TOKEN=YOUR_TOKEN ./gitlab.sh -h https://git.mycompany.com
```

To fetch from a GitLab instance installed at a subpath:
#### Example

**Linux/macOS (Bash):**
```sh
AUTH_TOKEN=YOUR_TOKEN ./gitlab.sh -h https://git.mycompany.com/gitlab -g team
```

**Windows (PowerShell):**
```powershell
$env:AUTH_TOKEN = "YOUR_TOKEN"
.\gitlab.ps1 -Group my-group -GitLabDomain https://my-gitlab.com
# Without group (projects you are a member of):
.\gitlab.ps1
# Without group, every project visible to the token:
.\gitlab.ps1 -IncludeAllRepos
```

#### Optional Environment Variables
- `CLONE_PROTOCOL`: Set to `ssh` to use SSH URLs instead of HTTPS. Defaults to `https`.

### Azure DevOps

This script fetches all repositories from a Azure DevOps organization.

#### Usage
```sh
./azure-devops.sh -o <organization> -p <project>
```

#### Description
This script fetches all repositories from a Azure DevOps project in the given organization.
Organization here refers to the tenant, and a project to the level of access controll in Azure.
One Organization has multiple Projects, which each can contain multiple Repositories.

##### Prerequisites

1. Azure CLI installed, via Brew `brew install azure-cli` or WinGet `winget install Microsoft.AzureCLI`
2. Azure DevOps Extension added, via Azure CLI `az extension add --name azure-devops`
3. Azure CLI must be logged in `az login` and user has access to the organization and project
   - The user needs the **Basic** access level; Stakeholder access does not include Azure Repos in private projects.
   - The user needs **Read** permission on the project's Git repositories, which the project's built-in Readers group grants.
   - Instead of `az login`, you can set the `AZURE_DEVOPS_EXT_PAT` environment variable to a personal access token with the **Code (Read)** scope.

#### Example

**Linux/macOS (Bash):**
```sh
./azure-devops.sh -o <organization> -p <project>
# Use -h flag for HTTPS URLs instead of SSH
./azure-devops.sh -o <organization> -p <project> -h
```

**Windows (PowerShell):**
```powershell
.\azure-devops.ps1 -Organization <organization> -Project <project>
# Use -UseHttps switch for HTTPS URLs instead of SSH
.\azure-devops.ps1 -Organization <organization> -Project <project> -UseHttps
```

