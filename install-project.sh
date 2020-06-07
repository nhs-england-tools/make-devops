#!/bin/bash
set -e

function main() {
  download
  dir=$(pwd)
  cd /tmp/make-devops
  make devops-copy DIR=$dir
  finish
}

function download() {
  curl -L \
    "https://github.com/nhsd-ddce/make-devops/tarball/master?$(date +%s)" \
    -o /tmp/make-devops.tar.gz
  tar -zxf /tmp/make-devops.tar.gz -C /tmp
  rm -rf \
    /tmp/make-devops.tar.gz \
    /tmp/make-devops*
  mv /tmp/nhsd-ddce-make-devops-* /tmp/make-devops
}

function finish() {
  tput setaf 2
  printf "\nDone! Please, see the project documentation for further instructions.\n\n"
  tput sgr0
}

main
