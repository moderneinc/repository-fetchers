## Repository Fetchers

This directory contains scripts that query a source code manager (SCM) to create a CSV file that contains a list of repositories and their details. This list of repositories can then be used for easy cloning with the [Moderne CLI](https://docs.moderne.io/user-documentation/moderne-cli/getting-started/cli-intro) or it can be used to help you create an [Organizations service](https://docs.moderne.io/administrator-documentation/moderne-platform/how-to-guides/org-service/).

The expected output looks similar to:

```csv
cloneUrl,branch
https://github.com/openrewrite/rewrite-spring,main
https://github.com/openrewrite/rewrite-recipe-markdown-generator,main
https://github.com/openrewrite/rewrite-docs,master
https://github.com/openrewrite/rewrite,main
https://github.com/openrewrite/rewrite-python,main
https://github.com/openrewrite/rewrite-migrate-java,main
https://github.com/openrewrite/rewrite-recommendations,main
https://github.com/openrewrite/rewrite-testing-frameworks,main
https://github.com/openrewrite/rewrite-gradle-tooling-model,main
https://github.com/openrewrite/rewrite-recipe-bom,main
```

## Supported SCMs
* [GitHub](#github)
* [Bitbucket Data Center](#bitbucket-data-center)
* [Bitbucket Cloud](#bitbucket-cloud)
* [GitLab](#gitlab)

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

#### Example
To fetch all repositories from a GitHub organization:
```sh
./github.sh my-organization
```


### Bitbucket Data Center

This script fetches all repositories from a Bitbucket Data Center instance.

#### Usage
```sh
./bitbucket-data-center.sh <bitbucket_url>
```

#### Description
This script fetches all repositories from the specified Bitbucket Data Center URL. If the `AUTH_TOKEN` environment variable is set, it will be used for authentication.

#### Example
To fetch all repositories from a Bitbucket Data Center instance:
```sh
AUTH_TOKEN=YOUR_TOKEN ./bitbucket-data-center.sh https://my-bitbucket.com/stash
```

### Bitbucket Cloud

This script fetches all repositories from a Bitbucket Data Center instance.

#### Usage
```sh
./bitbucket-cloud.sh -u username -p password <workspace>
```

#### Description
This script fetches all repositories from the specified Bitbucket Data Center URL. If the `AUTH_TOKEN` environment variable is set, it will be used for authentication.

#### Example
To fetch all repositories from a Bitbucket Data Center instance:
```sh
./bitbucket-cloud.sh -u YOUR_USERNAME -p APP_PASSWORD myworkspace
```

### GitLab

This script fetches all repositories from a GitLab instance or a specific group within a GitLab instance.

#### Usage
```sh
./gitlab.sh [-g <group>] [-h <gitlab_domain>]
```

#### Description
This script fetches all repositories from a GitLab instance or a specific group within a GitLab instance. The `AUTH_TOKEN` environment variable must be set for authentication. The `-g` option specifies a group to fetch repositories from. The `-h` option specifies the GitLab domain (defaults to `https://gitlab.com` if not provided).

#### Example
To fetch all repositories from a specific group on a custom GitLab domain:
```sh
AUTH_TOKEN=YOUR_TOKEN ./gitlab.sh -g my-group -h https://my-gitlab.com
```

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

#### Example
To fetch all repositories from an Azure DevOps organization and project:
```sh
./azure-devops.sh -o <organization> -p <project>
```

