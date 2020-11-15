# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.6] - 2020-06-11

### Added

- `wait-for-it` script within each image
- `ON_ERROR_STOP` flag for the `nhsd/postgres` image
- `yq` tool
- `nhsd/elasticsearch` image
- `nhsd/python` image
- `nhsd/python-app` image
- Improved Python module functionality
- Docker image template
- Kubernetes deployment template
- Project structure template

### Changed

- Provisioning of macOS `curl -L bit.ly/make-devops-macos | bash`
- Installation of the project `curl -L bit.ly/make-devops-project | bash`

## [0.7.5] - 2020-05-25

### Added

- Scan commits for secrets
- Ask user to input valid AWS account IDs
- Assume role from within modules
- Docker Compose parallel execution
- Provide consistent `nhsd/postgres` image variables and ability to run `.sql.gz` files

### Changed

- Refactor `k8s` module
- Update versions

## [0.7.4] - 2020-05-12

### Added

- Get ALB endpoint

### Changed

- Improve unit test output

## [0.7.3] - 2020-05-10

### Added

- LocalStack module

### Fixed

- Project synchronisation target executes from the main repository

### Changed

- Up to date Docker image versions
- Sandbox main process execution within library Docker image

## [0.7.2] - 2020-04-30

### Added

- Design pipelines
- Additional git pre-commit hook script

### Fixed

- Correct issue with the library Docker registry

## [0.7.1] - 2020-04-29

### Changed

- Refactor Docker targets
- Refactor AWS targets
- Include `make` in the `nhsd/tools` image

## [0.7.0] - 2020-04-27

### Changed

- Refactoring

## [0.6.7] - 2020-03-19

### Added

- Jenkins module

### Fixed

- K8s deployment targets
- Setup script failing if Python path is broken

### Changed

- Refactoring

## [0.6.6] - 2020-03-10

### Changed

- Refactor k8s module
- Update documentation

## [0.6.5] - 2020-03-04

### Changed

- Refactoring based on a user feedback

## [0.6.0] - 2020-01-28

### Changed

- Code in the open and move the repository to GitHub
- Throw an error if the prerequisites are not met

## [0.5.6] - 2020-01-27

### Changed

- Pin VirtualBox package to v6.1.0
- Pin Vagrant package to v2.2.6

### Fixed

- Maven installation on a new system

## [0.5.5] - 2020-01-26

### Added

- Installation of the Gradle and Maven
- Test project placeholder
- Alias to toggle natural scrolling
- Check if user home directory contains spaces
- Open manual after macOS provisioning

### Changed

- Git configuration
- Documentation
- More intuitive output while experiencing setup errors

## [0.5.4] - 2020-01-25

### Added

- Installation of the Golang
- More deployment profiles

### Changed

- Documentation
- Tests

## [0.5.3] - 2020-01-23

### Changed

- Structure of the k8s deployment scripts

## [0.5.2] - 2020-01-23

### Added

- Texas infrastructure configuration dependencies
- Pass options to the Terraform targets

### Changed

- Location of the Texas infrastructure configuration files, now being stored in the `var` directory
- Name of the macOS provisioning library to `macos.mk`
- Development environment setup scripts to improve user experience
- Documentation

## [0.5.1] - 2020-01-20

### Added

- Installation of the Avast Security antivirus
- Installation of the Cucumber Visual Studio Code extension
- Test library

### Changed

- Development environment setup scripts to improve user experience

### Fixed

- Node container file permissions

## [0.5.0] - 2020-01-19

### Added

- Various Docker library improvements
- Target to push repository snapshot to GitHub
- Installation of additional development dependencies

### Changed

- Name of the synchronisation target to `devops-synchronise`

### Fixed

- Slow execution of the `docker-run-node` target

## [0.0.9] - 2020-01-16

### Added

- Unique Docker container names for all the `docker-run-*` make targets

### Changed

- Version for `data` and `postgres` Docker images
- Kubernetes namespace naming for the production environment

## [0.0.8] - 2020-01-14

### Added

- Various Docker library improvements

### Changed

- ECR image location

### Fixed

- Issue with the automated dev setup

## [0.0.7] - 2020-01-12

### Added

- Docker image supporting functionality
- `USER_ID` and `GROUP_ID` variables
- Config directory

## [0.0.6] - 2020-01-10

### Fixed

- Synchronisation of the DevOps automation toolchain

## [0.0.5] - 2020-01-10

### Added

- Python virtual environment
- Node virtual environment
- Java virtual environment
- PHP composer image
- Terraform configuration in Visual Studio Code

### Changed

- Documentation
- Development environment setup

### Fixed

- Vagrant 2.2.6 and VirtualBox 6.1 incompatibility

## [0.0.4] - 2020-01-06

### Added

- Kubernetes library
- AWS S3 support
- Functionality to synchronise DevOps automation toolchain to the latest tag

### Fixed

- Non-existing `~/.ssh` directory on a clean operating system

## [0.0.3] - 2020-01-05

### Added

- Terraform library
- Oh My Zsh plugins to improve development environment configuration
- MacBook configuration settings

### Fixed

- Bug due to which installed software packages were not detected correctly

## [0.0.2] - 2020-01-03

### Added

- Script to install development dependencies in a convenient manner

### Changed

- Development environment setup scripts to improve user experience
- Documentation

## [0.0.1] - 2020-01-02

### Added

- Initial release of the DevOps automation toolchain scripts

[unreleased]: https://github.com/nhsd-exeter/make-devops/compare/v0.7.6...master
[0.7.6]: https://github.com/nhsd-exeter/make-devops/compare/v0.7.5...v0.7.6
[0.7.5]: https://github.com/nhsd-exeter/make-devops/compare/v0.7.4...v0.7.5
[0.7.4]: https://github.com/nhsd-exeter/make-devops/compare/v0.7.3...v0.7.4
[0.7.3]: https://github.com/nhsd-exeter/make-devops/compare/v0.7.2...v0.7.3
[0.7.2]: https://github.com/nhsd-exeter/make-devops/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/nhsd-exeter/make-devops/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/nhsd-exeter/make-devops/compare/v0.6.7...v0.7.0
[0.6.7]: https://github.com/nhsd-exeter/make-devops/compare/v0.6.6...v0.6.7
[0.6.6]: https://github.com/nhsd-exeter/make-devops/compare/v0.6.5...v0.6.6
[0.6.5]: https://github.com/nhsd-exeter/make-devops/compare/v0.6.0...v0.6.5
[0.6.0]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.5.6...v0.6.0
[0.5.6]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.5.5...v0.5.6
[0.5.5]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.5.4...v0.5.5
[0.5.4]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.5.3...v0.5.4
[0.5.3]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.5.2...v0.5.3
[0.5.2]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.5.1...v0.5.2
[0.5.1]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.5.0...v0.5.1
[0.5.0]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.0.9...v0.5.0
[0.0.9]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.0.8...v0.0.9
[0.0.8]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.0.7...v0.0.8
[0.0.7]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.0.6...v0.0.7
[0.0.6]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.0.5...v0.0.6
[0.0.5]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.0.4...v0.0.5
[0.0.4]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.0.3...v0.0.4
[0.0.3]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.0.2...v0.0.3
[0.0.2]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/compare/v0.0.1...v0.0.2
[0.0.1]: https://gitlab.mgmt.texasplatform.uk/uec/tools/make-devops/tree/v0.0.1
