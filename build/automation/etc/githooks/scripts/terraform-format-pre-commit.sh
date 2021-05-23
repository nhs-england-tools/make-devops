#!/bin/bash

if [ "$PROJECT_NAME" = "$DEVOPS_PROJECT_NAME" ]; then
  if [ true == $(make git-commit-has-changed-directory DIR=build/automation/lib/terraform/template PRECOMMIT=true) ]; then
    if ! make -s terraform-fmt DIR=build/automation/lib/terraform/template OPTS="-check -list=false" 2> /dev/null; then
      tput setaf 202
      printf "\n  $(echo $0 | sed "s;$PWD/;;"): Please, format the Terraform files in 'build/automation/lib/terraform/template'.\n"
      tput sgr0
      exit 1
    fi
  fi
fi
if [ true == $(make git-commit-has-changed-directory DIR=infrastructure PRECOMMIT=true) ]; then
  if ! make -s terraform-fmt DIR=infrastructure OPTS="-check -list=false" 2> /dev/null; then
    tput setaf 202
    printf "\n  $(echo $0 | sed "s;$PWD/;;"): Please, format the Terraform files in 'infrastructure'\n"
    tput sgr0
    exit 1
  fi
fi

# TODO: Add `make docker-run-terraform-tfsec`
# TODO: Add `make docker-run-terraform-checkov`
# TODO: Add `make docker-run-terraform-compliance`
# TODO: Add `make docker-run-config-lint`
