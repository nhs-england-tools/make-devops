#!/bin/bash

# TODO: We need a tag for `mstruebing/editorconfig-checker`

if [ "$PROJECT_NAME" = "$DEVOPS_PROJECT_NAME" ]; then
  docker run --rm \
    --volume=$PWD:/check mstruebing/editorconfig-checker \
    ec --exclude 'markdown|linux-amd64$|\.drawio|\.p12$'
else
  docker run --rm \
    --volume=$PWD:/check mstruebing/editorconfig-checker \
    ec --exclude 'build/automation|markdown|linux-amd64$|\.drawio|\.p12$'
fi
