#!/bin/bash
set -e

function main() {
  download
  cd /tmp/make-devops
  make macos-setup
  finish
}

function download() {
  echo curl -L \
    "https://github.com/nhsd-exeter/make-devops/tarball/${BRANCH_NAME:-master}?$(date +%s)" \
    -o /tmp/make-devops.tar.gz
  tar -zxf /tmp/make-devops.tar.gz -C /tmp
  rm -rf \
    /tmp/make-devops.tar.gz \
    /tmp/make-devops*
  mv /tmp/nhsd-exeter-make-devops-* /tmp/make-devops
}

function finish() {
  tput setaf 2
  printf "\nDone: Please, see the project documentation for further instructions.\n\n"
  tput sgr0
}

main
