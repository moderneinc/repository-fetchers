## Repository Fetchers

This directory contains scripts that can be used to fetch repositories. Below are the details of each script along with examples of how to invoke them and their required/optional arguments.

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

