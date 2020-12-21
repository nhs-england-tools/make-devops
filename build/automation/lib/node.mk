NODE_VERSION = 15.4.0

node-virtualenv: ### Setup Node.js virtual environment - optional: NODE_VERSION
	nvm install $(NODE_VERSION)
	nvm use $(NODE_VERSION)

node-check-versions: ### Check Node.js versions alignment
	echo "node library: $(NODE_VERSION) (current $(DEVOPS_PROJECT_VERSION))"
	echo "node library aws: none"
	echo "node virtual: $$(. /usr/local/opt/nvm/nvm.sh; nvm ls-remote | grep -o "[[:space:]]v[0-9]*\(\.[0-9]*\(\.[0-9]*\)\?\)\?" | sed "s/v//g" | sort -V -r | head -n 1 | sed "s/^[[:space:]]*//g") (latest)"
	echo "node docker: $$(make docker-repo-list-tags REPO=node | grep -w "^[0-9]*\(\.[0-9]*\(\.[0-9]*\)\?\)\?-alpine$$" | sort -V -r | head -n 1 | sed "s/-alpine//g" | sed "s/^[[:space:]]*//g") (latest)"
	echo "node aws: unknown"

.SILENT: \
	node-check-versions
