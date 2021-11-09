#!/bin/bash
set -e

function main() {
  dir=$(pwd)
  clone || download; cd "$HOME/.make-devops"
  make devops-copy DIR=$dir
  finish
}

function clone() {
  if ! [ -d "$HOME/.make-devops/.git" ]; then
    cd "$HOME"
    rm -rf make-devops .make-devops
    git clone https://github.com/nhsd-exeter/make-devops.git
    mv make-devops .make-devops
  fi
  cd "$HOME/.make-devops"
  git pull --all
  git checkout ${BRANCH_NAME:-main}
}

function download() {
  curl -L \
    "https://github.com/nhsd-exeter/make-devops/tarball/${BRANCH_NAME:-main}?$(date +%s)" \
    -o /tmp/make-devops.tar.gz
  tar -zxf /tmp/make-devops.tar.gz -C /tmp
  rm -rf \
    /tmp/make-devops.tar.gz \
    /tmp/make-devops* \
    "$HOME/.make-devops"
  mv /tmp/nhsd-exeter-make-devops-* "$HOME/.make-devops"
}

function finish() {
  tput setaf 2
  printf "\nDone: Please, see the project documentation for further instructions.\n\n"
  tput sgr0
}

main
