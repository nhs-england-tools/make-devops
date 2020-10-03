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
    - [From the Command-line](#from-the-command-line)
    - [Using CI/CD Pipelines](#using-cicd-pipelines)
  - [Architecture](#architecture)
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

- Use iTerm2 and Visual Studio Code
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

- Describe how to switch each individual component to the dev mode
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

### From the Command-line

    make deploy PROFILE=dev

### Using CI/CD Pipelines

List all the pipelines and their purpose

## Architecture

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

List all the environments

- dev
- perf
- demo
- live

Describe how to provision and deploy to a task branch environment
