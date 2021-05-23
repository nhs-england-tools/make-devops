#!/bin/bash

if [ $(make git-check-if-branch-name-is-correct) == false ]; then
  tput setaf 202
  printf "\n  $(echo $0 | sed "s;$PWD/;;"): Branch name '$(git symbolic-ref --short HEAD 2> /dev/null ||:)' does not meet the accepted branch naming convention\n"
  tput sgr0
  exit 1
fi
