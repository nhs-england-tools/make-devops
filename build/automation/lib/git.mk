_GIT_CONFIG_TIMESTAMP_FILE = $(TMP_DIR)/.git-config-secrets.timestamp
#_GIT_CONFIG_FORCE =

git-config: ### Configure local git repository
	if ([ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1) && ([ ! -f $(_GIT_CONFIG_TIMESTAMP_FILE) ] || [[ "$(_GIT_CONFIG_FORCE)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]) && [ $(BUILD_ID) -eq 0 ]; then
		git config branch.autosetupmerge false
		git config branch.autosetuprebase always
		git config commit.gpgsign true
		git config core.autocrlf input
		git config core.filemode true
		git config core.hidedotfiles false
		git config core.hooksPath $(GITHOOKS_DIR_REL)
		git config core.ignorecase false
		git config pull.rebase true
		git config push.default current
		git config push.followTags true
		git config rebase.autoStash true
		git config remote.origin.prune true
		echo "build/automation/etc/githooks/commit-msg" > $(PROJECT_DIR)/.git/hooks/commit-msg
		chmod +x $(PROJECT_DIR)/.git/hooks/commit-msg
		echo "build/automation/etc/githooks/pre-commit" > $(PROJECT_DIR)/.git/hooks/pre-commit
		chmod +x $(PROJECT_DIR)/.git/hooks/pre-commit
		echo "build/automation/etc/githooks/prepare-commit-msg" > $(PROJECT_DIR)/.git/hooks/prepare-commit-msg
		chmod +x $(PROJECT_DIR)/.git/hooks/prepare-commit-msg
		git secrets --register-aws
		make git-secrets-load
		echo $(BUILD_TIMESTAMP) > $(_GIT_CONFIG_TIMESTAMP_FILE)
	fi

git-check-if-branch-name-is-correct: ### Check if the branch name meets the accepted branch naming convention
	if [[ $(BUILD_BRANCH) =~ $(GIT_BRANCH_PATTERN) ]]; then
		echo true
	else
		echo false
	fi

# ==============================================================================

git-secrets-load:
	make git-secrets-clear
	for file in $$(ls -1 $(ETC_DIR)/git-secrets/*-banned.regexp); do
		for line in $$(cat $$file); do
			make git-secrets-add-banned PATTERN=$$line
		done
	done
	for file in $$(ls -1 $(ETC_DIR)/git-secrets/*-allowed.regexp); do
		for line in $$(cat $$file); do
			make git-secrets-add-allowed PATTERN=$$line
		done
	done

git-secrets-add-banned: ### Add banned secret pattern - mandatory: PATTERN=[banned pattern]
	exists=false
	hash_pattern=$$(echo '$(PATTERN)' | md5sum | cut -f1 -d' ')
	for line in $$(git-secrets --list | grep 'secrets.patterns' | sed 's/secrets.patterns //'); do
		hash_line=$$(echo ''$$line'' | md5sum | cut -f1 -d' ')
		[ $$hash_line == $$hash_pattern ] && exists=true ||:
	done
	[ $$exists == false ] && git config --add secrets.patterns '$(PATTERN)' ||:

git-secrets-add-allowed: ### Add allowed secret pattern - mandatory: PATTERN=[allowed pattern]
	exists=false
	hash_pattern=$$(echo '$(PATTERN)' | md5sum | cut -f1 -d' ')
	for line in $$(git-secrets --list | grep 'secrets.allowed' | sed 's/secrets.allowed //'); do
		hash_line=$$(echo ''$$line'' | md5sum | cut -f1 -d' ')
		[ $$hash_line == $$hash_pattern ] && exists=true ||:
	done
	[ $$exists == false ] && git config --add secrets.allowed '$(PATTERN)' ||:

git-secrets-clear: ### Clear git secret scanning settings
	git config --unset-all secrets.patterns ||:
	git config --unset-all secrets.allowed ||:

git-secrets-scan-repo-history: ### Scan repository histroy for any secrets
	git secrets --scan-history

git-secrets-scan-repo-files: ### Scan repository files for any secrets
	git secrets --scan

# ==============================================================================

git-check-if-commit-changed-directory: ### Check if any file changed in the given directory - mandatory: DIR=[directory]; optional: PRECOMMIT=true; return: true|false
	if [ "$(PRECOMMIT)" == true ]; then
		compare_to=HEAD
	elif [ "$(BUILD_BRANCH)" != master ]; then
		compare_to=master
	else
		compare_to=HEAD^
	fi
	git diff --name-only --cached $$compare_to --diff-filter=ACDMRT | grep --quiet '^$(DIR)' && echo true || echo false

git-commit-get-hash git-hash: ### Get short commit hash - optional: COMMIT=[commit, defaults to HEAD]
	git rev-parse --short $(or $(COMMIT), HEAD) 2> /dev/null || echo unknown

git-commit-get-timestamp git-ts: ### Get commit timestamp - optional: COMMIT=[commit, defaults to HEAD]
	TZ=UTC git show -s --format=%cd --date=format-local:%Y%m%d%H%M%S $(or $(COMMIT), HEAD) | cat 2> /dev/null || echo unknown

git-commit-get-message git-msg: ### Get commit message - optional: COMMIT=[commit, defaults to HEAD]
	git log --format=%B -n 1 $(or $(COMMIT), HEAD)

# ==============================================================================

git-tag-is-environment-deployment: ### Check if a commit is tagged as environment deployment - mandatory: PROFILE=[profile name]; optional: COMMIT=[commit, defaults to master]; return: true|false
	commit=$(or $(COMMIT), master)
	(git show-ref --tags -d | grep $$(git rev-parse $$commit) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -- -$(ENVIRONMENT)$$) > /dev/null 2>&1 && echo true || echo false

git-tag-create: ### Tag a commit - mandatory: TAG=[tag name]; optional: COMMIT=[commit, defaults to master]
	commit=$(or $(COMMIT), master)
	git tag $(TAG) $$commit
	git push origin $(TAG)

git-tag-create-environment-deployment: ### Tag environment deployment as `[YYYYmmddHHMMSS]-[env]` - mandatory: PROFILE=[profile name]; optional: COMMIT=[release candidate tag name, defaults to master]
	[ $(PROFILE) == local ] && (echo "ERROR: Please, specify the PROFILE"; exit 1)
	commit=$(or $(COMMIT), master)
	tag=$(BUILD_TIMESTAMP)-$(ENVIRONMENT)
	make git-tag-create TAG=$$tag COMMIT=$$commit

git-tag-get-environment-deployment: ### Get the latest environment deployment tag for the whole repository or just the specified commit - mandatory: PROFILE=[profile name]; optional: COMMIT=[commit]
	[ $(PROFILE) = local ] && (echo "ERROR: Please, specify the PROFILE"; exit 1)
	if [ -z "$(COMMIT)" ]; then
		git show-ref --tags -d | grep ^$(COMMIT) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -- -$(ENVIRONMENT)$$ | sort -r | head -n 1
	else
		git show-ref --tags -d | grep ^$$(git rev-parse --short $(COMMIT)) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -- -$(ENVIRONMENT)$$ | sort -r | head -n 1
	fi

git-tag-get-latest: ### Get the latest tag on the current branch - return [YYYYmmddHHMMSS]-[*]
	git tag --sort version:refname | grep '^[0-9]*'| sort -r | head -n 1

git-tag-list: ### List tags of a commit - optional: COMMIT=[commit, defaults to master],PROFILE=[profile name]
	commit=$(or $(COMMIT), master)
	tags=$$(git show-ref --tags -d | grep $$(git rev-parse $$commit) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -Eo ^[0-9]*-[a-z]*$$ ||:)
	[ $(PROFILE) != local ] && tags=$$(echo "$$tags" | grep -- -$(ENVIRONMENT)$$)
	echo "$$tags"

git-tag-clear: ### Remove tags from the specified commit - optional: COMMIT=[commit, defaults to master]
	commit=$(or $(COMMIT), master)
	for tag in $$(git show-ref --tags -d | grep $$(git rev-parse $$commit) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -Eo ^[0-9]*-[a-z]*$$); do
		git tag -d $$tag
		git push --delete origin $$tag 2> /dev/null ||:
	done

# ==============================================================================

.SILENT: \
	git-check-if-branch-name-is-correct \
	git-commit-get-hash git-hash \
	git-commit-get-message git-msg \
	git-commit-get-timestamp git-ts \
	git-check-if-commit-changed-directory \
	git-tag-get-environment-deployment \
	git-tag-get-latest \
	git-tag-is-environment-deployment \
	git-tag-list
