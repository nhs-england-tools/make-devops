# Todo

## Table of contents

- [Todo](#todo)
  - [Table of contents](#table-of-contents)
  - [Regular tasks](#regular-tasks)
  - [One off tasks](#one-off-tasks)
    - [General](#general)

List here all the technical tasks for prioritisation that need to be discussed with the team but are not ready yet to be placed on the backlog. This should form a holistic view of the state of the project and show the direction for incremental development and refactoring of certain areas of the software listed below. The idea behind this list is to ensure backlog hygiene and that it only consists of stories that can be completed within the next two sprints. Therefore, the focus can be changed dynamically depending on the business need.

This document must be discussed regularly with the Tech Lead and considered in the context of the [Engineering Quality Checks](https://github.com/NHSDigital/software-engineering-quality-framework/blob/master/quality-checks.md) provided as a guidance by NHS Digital Product Development directorate.

## Regular tasks

- Review technical documentation
- Upgrade dependencies to the latest version
- Update your macOS by running the `curl -L bit.ly/make-devops-macos-setup | bash` command

## One off tasks

### General

- Automation
  - Develop a mechanism to autoupdate Make DevOps scripts in repos along with creating a PR for it
- Refactoring
  - Make sure the `infrastructure` directory is custom and move away test files from it
  - Run `kubectl` from container
  - Consider using https://github.com/pre-commit/pre-commit for githooks
- Infrastructure
  - [Limit container resources](https://docs.docker.com/config/containers/resource_constraints/)
  - [Decouple data](https://www.terraform.io/docs/modules/composition.html)
  - More k8s example [network policies](https://www.stackrox.com/post/2019/04/setting-up-kubernetes-network-policies-a-detailed-guide/)
- Security
  - Replace the development SSL certificate by a secure one loaded by the CI/CD pipeline
  - Perform security analysis using [prowler](https://github.com/toniblyx/prowler)
- Development
  - Provide `tdd` and `dev` targets for Python to support development workflow
  - Implement `VERBOSE` flag to show/hide verbose script execution
  - Issue with the JS file formatting, see [Jsx indentation conflict vscode and eslint](https://stackoverflow.com/questions/48674208/jsx-indentation-conflict-vscode-and-eslint)
- Documentation
  - List features by module
  - Configuration of a CI/CD system, i.e. set mandatory variables
  - Docker library image usage
- Containers
  - Refactor the execution logic for the `postgres` Docker image
  - Should the `_replace_variables()` and `am_i_root()` functions be moved to `libinit.sh` script? E.g. https://github.com/bitnami/bitnami-docker-nginx/tree/master/1.18/debian-10/prebuildfs/opt/bitnami/scripts
  - Create reverse proxy configuration for `nginx`
  - Add `redis` for local Amazon ElastiCache
  - Add `dynamodb` for local Amazon DynamoDB
- Others
  - Move iTerm2 config file into the repository
