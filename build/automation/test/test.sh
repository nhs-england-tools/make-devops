#!/bin/bash

function mk_test() {
    target=$1; shift
    test $@ && \
        mk_test_pass "$target" || \
        mk_test_fail "$target"
}

function mk_test_pass() {
    (
        printf " ["
        mk_test_not_debugging && tput setaf 64 # green
        printf "pass"
        mk_test_not_debugging && tput sgr 0
        printf "] $*\n"
    ) >&5
}

function mk_test_fail() {
    (
        printf " ["
        mk_test_not_debugging && tput setaf 196 # red
        printf "fail"
        mk_test_not_debugging && tput sgr 0
        printf "] $*\n"
    ) >&5
}

function mk_test_skip() {
    (
        printf " ["
        mk_test_not_debugging && tput setaf 21 # blue
        printf "skip"
        mk_test_not_debugging && tput sgr 0
        printf "] $*\n"
    ) >&5
}

function mk_test_skip_if_not_macos() {
    if [ "$(uname)" != "Darwin" ]; then
        (
            printf " ["
            mk_test_not_debugging && tput setaf 21 # blue
            printf "skip"
            mk_test_not_debugging && tput sgr 0
            printf "] $*\n"
        ) >&5
    else
        return 1
    fi
}

function mk_test_proceed_if_macos() {
    if [ "$(uname)" = "Darwin" ]; then
        return 0
    else
        return 1
    fi
}

function mk_test_not_debugging() {
    [[ ! "$DEBUG" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]] && return 0 || return 1
}

export -f mk_test
export -f mk_test_fail
export -f mk_test_pass
export -f mk_test_proceed_if_macos
export -f mk_test_skip
export -f mk_test_skip_if_not_macos
export -f mk_test_not_debugging
