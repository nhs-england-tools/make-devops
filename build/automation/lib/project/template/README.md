# Project Name

## Table of Contents

- [Project Name](#project-name)
  - [Table of Contents](#table-of-contents)
  - [Quick Start](#quick-start)
    - [Development Recommendations](#development-recommendations)
    - [Local Environment Configuration](#local-environment-configuration)
    - [Local Project Setup](#local-project-setup)
  - [Development](#development)
  - [Testing](#testing)
  - [Deployment](#deployment)
    - [AWS Access](#aws-access)
    - [Deployment From the Command-line](#deployment-from-the-command-line)
    - [CI/CD Pipelines](#cicd-pipelines)
  - [Architecture](#architecture)
    - [Technology Stack](#technology-stack)
    - [System Context](#system-context)
    - [Container Diagram](#container-diagram)
    - [Component Diagram](#component-diagram)
    - [Processes and Data Flow](#processes-and-data-flow)
    - [Interfaces](#interfaces)
    - [System Quality Attributes](#system-quality-attributes)
  - [Operation](#operation)
    - [Observability](#observability)
    - [Backups](#backups)
    - [Cloud Environments](#cloud-environments)

## Quick Start

### Development Recommendations

- Use iTerm2 and Visual Studio Code, which will be installed automatically for you in the next steps
- Before starting any work, please read [CONTRIBUTING.md](CONTRIBUTING.md)

### Local Environment Configuration

    make macos-setup
    make devops-setup-aws-accounts
    make trust-certificate

### Local Project Setup

    make build
    make start log
    open https://ui.project.local:8443

## Development

- Describe how to
  - Connect to a local database
  - Interact with a mock component
  - Switch each individual component to the dev mode
- Provide guidance on how to use feature toggles and branching by abstraction

## Testing

List all the type of test suites included and provide instructions how to execute them

- Unit
- Integration
- Contract
- End-to-end
- Performance
- Security
- Smoke

## Deployment

### AWS Access

To be able to interact with a remote environment, please make sure you have set up your AWS CLI credentials and
MFA to the right AWS account using the following command

    tx-mfa

### Deployment From the Command-line

    make deploy PROFILE=dev

### CI/CD Pipelines

List all the pipelines and their purpose

- Development
- Test
- Cleanup
- Production (deployment)

## Architecture

### Technology Stack

What are the technologies and programing languages used to implement the solution

### System Context

Include a link to the System Context diagram

### Container Diagram

Include a link to the Container diagram

### Component Diagram

Include a link to the Component diagram

### Processes and Data Flow

Include a link to the Processes and Data Flow diagram

### Interfaces

Document all the system external interfaces

### System Quality Attributes

- Accessibility, usability
- Resilience, durability, fault-tolerance
- Scalability, elasticity
- Interoperability
- Security

## Operation

### Observability

- Logging
- Tracing
- Monitoring
- Alerting
- Fitness functions

What are the links of the supporting systems?

### Backups

- Frequency and type of the backups
- Instructions on how to recover the data

### Cloud Environments

List all the environments and their relation to profiles

- dev
- test
- demo
- live

Describe how to provision and deploy to a task branch environment
