# Make DevOps

If you hear your teams or individuals saying _"It will take days to onboard a new member..."_, _"It works on my machine..."_ or _"Our pipeline is to complex and no one really understands how it all works..."_ then perhaps you need to take an interest in this project.

## Use cases

- Fully automated development environment setup for macOS
- Highly customisable project toolchain (inspired by dotfiles) for advanced \*nix shell scripting
- Building blocks to support a clean implementation of CI/CD pipelines

## Features

- Shell native
- Automated setup
- Local development flow support
- Pipeline consistency and testability
- Highly customisable and flexible implementation
- Integration with a 3rd-party packages and services
  - [Docker](build/automation/lib/docker.mk)
  - [Kubernetes](build/automation/lib/k8s.mk)
  - [Terraform](build/automation/lib/terraform.mk)
  - [AWS](build/automation/lib/aws.mk)
  - SonarQube (coming soon)
  - Twistlock (coming soon)
  - Notifications, e.g. email and Slack (coming soon)
  - Technology radar (coming soon)
  - [macOS](build/automation/lib/macos.mk)
- Unit and integration [tests](build/automation/test)
- Example of a monolithic repository structure that consists of multiple projects
- Architectural decision record [template](documentation/adr/README.md)
- Deployment [profiles](build/automation/var/profile/README.md)
- Data Docker image to [run SQL scripts](build/docker/data/assets/sbin/entrypoint.sh) against a database instance
- Tools Docker image with [various command-line utilities](build/docker/tools/Dockerfile) pre-installed
- Pre-commit [git hook](build/automation/etc/githooks/pre-commit) example
- Visual Studio Code and iTerm configuration
- Virtual environments for Python, Go, Java and Node.js
- AWS MFA [script](build/automation/bin/texas-mfa)
- Toggle natural scrolling [script](build/automation/bin/toggle-natural-scrolling)
- Remote pair programming and [live collaboration](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare)

## Installation

- To set up your development environment on a MacBook run `curl -L bit.ly/make-devops | bash`
- For a project toolchain integration, copy the content of this repository to your project's root directory, commit your changes then run `make devops-synchronise`
- Use make targets to support your CI/CD flow

## Usage

- Run `make help-all` to see all available targets
- Update the toolchain scripts to the most recent version by executing `make devops-synchronise`
- Use `make devops-print-variables` to print out all the effective variables. Include `PROFILE=[name]` to evaluate profile specific variables
- To run unit test suite use `make devops-test-suite` or alternatively to run a single one execute `make devops-test-single NAME=[test target name]`. Set the `DEBUG=true` flag to run the tests in the verbose mode
- To provision your macOS run `make dev-setup` or alternatively update configuration `make dev-config`

## Conventions

- Set all the profile specific information in a `build/automation/var/profile/[name].mk` file
- Set all the project specific information in the `build/automation/var/project.mk` file. There is set of mandatory variables that must be defined for the library to function correctly. For more details, please refer to the `build/automation/var/project.mk.default` file
- Your development flow should be described in the main `Makefile` in the root directory of the project. Content of that file must meet certain implementation requirements and include some predefined sections
- Create custom helper targets in the `build/automation/var/helpers.mk` file. These targets should be lower-level targets supporting your project's development flow
- If a library target does not work in the expected way there are two ways of solving that issue
  - Create a patch, raise an MR and assign it to one of the library maintainers
  - Override the make target by creating it with the same name in the `build/automation/var/override.mk` file
- Target name convention
  - Use `descriptive-name`
  - Prefix target with the underscore i.e. `_descriptive-name` to indicate that it is a 'private' target
  - Do not exceed 40 characters
- Target help convention
  - Sample format is `# Target description - mandatory: ARG1=[argument description]; optional: ARG2="argument-value"; returns: [string]`
  - Prefix with `#` to indicate project development flow target listed by `make help` or `help-project-flow`
  - Prefix with `##` to indicate development supporting target listed by `make help-project-supporting`
  - Prefix with `###` to indicate library target, use `make help-all` to see the full list of available targets
  - An argument is mandatory when target cannot function without it being specified and this argument is not a configuration option
  - An argument is optional when it is provided by a profile, however it is intended to be set from the command-line depending on the context
- Best practices
  - Use the same names for secret keys and make variables defined in your profiles
  - Group variables logically, e.g. `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` create a one group
  - Sort a group of variables alphabetically if there is no direct correlation between them, e.g. `TF_VAR_route53_terraform_state_key`, `TF_VAR_vpc_terraform_state_key`
  - Never modify library files, except the `Makefile` and files that are in the `build/automation/var` directory which are project-specific
  - Always use a single tab character for code indentations
  - Naming
    - ECR: `$(PROJECT_GROUP)/$(PROJECT_NAME)/$(NAME)`
    - K8s namespace: `$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)-$(PROFILE)` or `$(PROJECT_GROUP_SHORT)-$(PROFILE)`

## Design

Here is a list of guiding principles to extend the library as well as to build project specific CI/CD pipeline

- Usability and simplicity
- Principle of least surprise
- Low coupling high cohesion
- A product team has full control over their pipeline execution and owns the pipeline code
- Pipeline implementation has to meet requirements specified by the platform
- Adoption of the clean code best practices
- Common pipeline is a template pipeline that consists of building blocks
- Implementation is independent from the CI/CD system, we need just a 'scheduler'
- Technology agnostic and universal design that can support Java, .NET, Python, Go, Node and others
- Elements of the pipeline can be executed locally as one-liners, e.g. `'run' build` or `'run' test`
- Pipeline runs anywhere, e.g. any \*NIX like system

## Todo

- Update Git usage instructions
- Add `git publish` alias and other, see [Useful Git aliases](https://gist.github.com/robmiller/6018582)
- Issue with the JS file formatting, see [Jsx indentation conflict vscode and eslint](https://stackoverflow.com/questions/48674208/jsx-indentation-conflict-vscode-and-eslint)
- Why `git checkout -b branch` forces then `git push origin`
- Run `make devops-synchronise` from the downloaded submodule
- Move iTerm2 config file into the repository

## Gotchas

- Bash
  - [Escape single quotes](https://stackoverflow.com/questions/1250079/how-to-escape-single-quotes-within-single-quoted-strings)
  - [Export JSON to environment variables](https://stackoverflow.com/questions/48512914/exporting-json-to-environment-variables)
  - [Remove colours from output](https://stackoverflow.com/questions/17998978/removing-colors-from-output)
- Docker
  - [Python Docker base image](https://pythonspeed.com/articles/alpine-docker-python/)
