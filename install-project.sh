#!/bin/bash
set -e

function main() {
  dir=$(pwd)
  download
  make devops-copy DIR=$dir
  finish
}

function download() {
  if ! [ -d "$HOME/.make-devops/.git" ]; then
    cd "$HOME"
    rm -rf make-devops .make-devops
    git clone https://github.com/nhsd-exeter/make-devops.git
    mv make-devops .make-devops
  fi
  cd "$HOME/.make-devops"
  git pull --all
  git checkout ${BRANCH_NAME:-master}
}

function finish() {
  tput setaf 2
  printf "\nDone: Please, see the project documentation for further instructions.\n\n"
  tput sgr0
}

main
