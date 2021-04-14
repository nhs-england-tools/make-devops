#!/bin/bash
set -e

function main() {
  download
  cd /tmp/make-devops
  make macos-config
  finish
}

function download() {
  curl -L \
    "https://github.com/nhsd-exeter/make-devops/tarball/master?$(date +%s)" \
    -o /tmp/make-devops.tar.gz
  tar -zxf /tmp/make-devops.tar.gz -C /tmp
  rm -rf \
    /tmp/make-devops.tar.gz \
    /tmp/make-devops*
  mv /tmp/nhsd-exeter-make-devops-* /tmp/make-devops
}

function finish() {
  tput setaf 2
  printf "\Done: Configure development dependencies\n\n"
  tput sgr0
}

main
