# Jenkins

## Setup

Here are the items to consider and a pattern for setting up a Jenkins pipeline:

- Item name: `$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)-development|test|tag|production|cleanup`
- Display name: `Project Name (Development|Test|Tag|Cleanup)` or just `Project Name` for the production deployment
- Branch Sources - Git - Project Repository
- Branch Sources - Git - Credentials
- Branch Sources - Git - Behaviours:
  - `Discover branches`
  - `Check out to matching local branch`
  - `Filter by name (with wildcards)`, e.g. `master`, `task/*`
- Branch Sources - Git - Property strategy: `Suppress automatic SCM triggering`
- Build Configuration - Script Path: `build/jenkins/Jenkinsfile.development|test|tag|production|cleanup`

For production:

- Branch Sources - Git - Behaviours:
  - `Discover tags` only
- Branch Sources - Git - Build strategies:
  - `Tags`, `Ignore tags older than` set to 1

## GitHub Integration

For an integration with a GitHub repository make use of the GitHub Apps, i.e. the `Texas Jenkins (read-only)`.

- Branch Sources - GitHub - Credentials - GHApp
- Branch Sources - GitHub - Repository HTTPS URL
