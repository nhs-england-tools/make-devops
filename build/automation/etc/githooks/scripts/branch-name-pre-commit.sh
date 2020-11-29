#!/bin/bash

branch=$(git symbolic-ref --short HEAD 2> /dev/null ||:)
if [ -n "$branch" ] && ! [[ $branch =~ ^(master|main|develop)$|^(task|story|epic|spike|fix|test|release|migration)/[A-Za-z]{2,5}-[0-9]{1,5}_[A-Za-z0-9_]{4,32}$ ]]; then
  echo "$0: Branch name '$branch' does not meet the accepted branch naming convention"
  exit 1
fi
