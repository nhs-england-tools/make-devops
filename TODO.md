# TODO

- Create AWS RDS PostgreSQL infrastructure module
- Containers
  - Refactor the execution logic for the `postgres` Docker image
  - Should the `configure()` and `_replace_variables()` functions be moved to `libinit.sh` script?
  - Move away from `openjdk` in favour of `adoptopenjdk`
  - Conditional push to the Docker Hub registry
  - Create reverse proxy configuration for `nginx`
  - Add `redis` for local Amazon ElastiCache
  - Add `elasticsearch` for local Amazon Elasticsearch
  - Add `dynamodb` for local Amazon DynamoDB
- 'Untexify' the project, e.g. in the `ssl.mk` module we can find references to the `$(TEXAS_HOSTED_ZONE_NONPROD)` and `$(TEXAS_HOSTED_ZONE_PROD)` variables
- Add `git publish` alias and other, see [Useful Git aliases](https://gist.github.com/robmiller/6018582)
- Issue with the JS file formatting, see [Jsx indentation conflict vscode and eslint](https://stackoverflow.com/questions/48674208/jsx-indentation-conflict-vscode-and-eslint)
- Why `git checkout -b branch` forces then `git push origin`
- Move iTerm2 config file into the repository
