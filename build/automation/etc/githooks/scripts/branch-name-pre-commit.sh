#!/bin/bash

branch=$(git symbolic-ref --short HEAD)
if ! [[ $branch =~ ^master|^develop|^(task|story|spike|fix|release|migration)/[a-zA-Z0-9_-].* ]]; then
  echo "$0: Branch name '$branch' does not meet the accepted branch naming convention"
  exit 1
fi
