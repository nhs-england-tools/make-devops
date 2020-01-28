#!/bin/bash
set -e

function main() {
    curl -L \
        "https://github.com/nhsd-ddce/make-devops/tarball/master?$(date +%s)" \
        -o /tmp/make-devops.tar.gz
    tar -zxf /tmp/make-devops.tar.gz -C /tmp
    rm -rf \
        /tmp/make-devops.tar.gz \
        /tmp/make-devops*
    mv /tmp/nhsd-ddce-make-devops-* /tmp/make-devops
    cd /tmp/make-devops
    make dev-setup $*
    tput setaf 2
    printf "\nDone! Please see the \"Setting up your macOS using Make DevOps\" manual for further instructions\n\n"
    tput sgr0
}

main $*
