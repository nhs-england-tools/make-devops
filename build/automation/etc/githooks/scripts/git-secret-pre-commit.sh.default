#!/bin/bash

export PATH=$(git rev-parse --show-toplevel)/build/automation/bin:$PATH
git secrets --pre_commit_hook -- "$@"
