#!/bin/bash

export PATH=$(git rev-parse --show-toplevel)/build/automation/bin:$PATH
git secrets --prepare_commit_msg_hook -- "$@"
