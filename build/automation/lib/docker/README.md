# Docker

## General

Build script functionality

- Pre-defined directory structure
- Source code provided as an archive for a transparent and consistent build process
- Self-signed SSL certificate to ensure traffic is encrypted in transit
- Metadata variables and labels populated with the image build details
- Template-based versioning
- `goss` tests

## Library images

Some of the benefits of using the library images

- Alpine-based images
- Locale and timezone set accordingly to the location
- `bash`, `curl` and `gosu` commands included
- `entrypoint`, `wait-for-it`, `init` and `run` scripts
- `prepare_configuration_files`, `replace_variables` and `set_file_permissions` functions
- Process debugging and tracing functionality
- Support to run process as a non-root system user
- [Instana](https://www.instana.com/) support

## Template images

- Usage examples
- Health check included

## TODO

- Convert examples to templates
- Remove python-app or convert it to a template

## Status

| Category                     | Badges                                                                                                                                                                                                                                                              |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Docker `elasticsearch` image | [![Version](https://images.microbadger.com/badges/version/nhsd/elasticsearch.svg)](http://microbadger.com/images/nhsd/elasticsearch)&nbsp;[![Docker Hub](https://img.shields.io/docker/pulls/nhsd/elasticsearch.svg)](https://hub.docker.com/r/nhsd/elasticsearch/) |
| Docker `nginx` image         | [![Version](https://images.microbadger.com/badges/version/nhsd/nginx.svg)](http://microbadger.com/images/nhsd/nginx)&nbsp;[![Docker Hub](https://img.shields.io/docker/pulls/nhsd/nginx.svg)](https://hub.docker.com/r/nhsd/nginx/)                                 |
| Docker `node` image          | [![Version](https://images.microbadger.com/badges/version/nhsd/node.svg)](http://microbadger.com/images/nhsd/node)&nbsp;[![Docker Hub](https://img.shields.io/docker/pulls/nhsd/node.svg)](https://hub.docker.com/r/nhsd/node/)                                     |
| Docker `postgres` image      | [![Version](https://images.microbadger.com/badges/version/nhsd/postgres.svg)](http://microbadger.com/images/nhsd/postgres)&nbsp;[![Docker Hub](https://img.shields.io/docker/pulls/nhsd/postgres.svg)](https://hub.docker.com/r/nhsd/postgres/)                     |
| Docker `python` image        | [![Version](https://images.microbadger.com/badges/version/nhsd/python.svg)](http://microbadger.com/images/nhsd/python)&nbsp;[![Docker Hub](https://img.shields.io/docker/pulls/nhsd/python.svg)](https://hub.docker.com/r/nhsd/python/)                             |
| Docker `python-app` image    | [![Version](https://images.microbadger.com/badges/version/nhsd/python-app.svg)](http://microbadger.com/images/nhsd/python-app)&nbsp;[![Docker Hub](https://img.shields.io/docker/pulls/nhsd/python-app.svg)](https://hub.docker.com/r/nhsd/python-app/)             |
| Docker `tools` image         | [![Version](https://images.microbadger.com/badges/version/nhsd/tools.svg)](http://microbadger.com/images/nhsd/tools)&nbsp;[![Docker Hub](https://img.shields.io/docker/pulls/nhsd/tools.svg)](https://hub.docker.com/r/nhsd/tools/)                                 |
