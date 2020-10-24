#!/bin/bash

if [ "$PROJECT_NAME" = "$DEVOPS_PROJECT_NAME" ]; then
  docker run --rm \
    --volume=$PWD:/check \
    mstruebing/editorconfig-checker:2.2.0 \
      ec --exclude 'markdown|linux-amd64$|\.drawio|\.p12|\.so$'
else
  docker run --rm \
    --volume=$PWD:/check \
    mstruebing/editorconfig-checker:2.2.0 \
      ec --exclude 'build/automation|markdown|linux-amd64$|\.drawio|\.p12|\.so$'
fi
