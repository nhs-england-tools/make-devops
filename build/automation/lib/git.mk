git-config: ### Configure local git repository
	if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1; then
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
		make git-secrets-add-allowed PATTERN=000000000000
	fi

# ==============================================================================

git-secrets-add-allowed: ### Add allowed secret pattern - mandatory: PATTERN=[allowed pattern]
	git-secrets --list | grep -q "secrets.allowed $(PATTERN)" \
		|| git config --add secrets.allowed '$(PATTERN)'

git-secrets-scan-history: ### Scan git histroy for any secrets
	git secrets --scan-history

# ==============================================================================

git-commit-has-changed-directory: ### Determin if any file changed in directory - mandatory: DIR=[directory]; return: true|false
	git diff --name-only --diff-filter=AMDR --cached HEAD^ | grep --quiet '$(DIR)' && echo true || echo false

git-commit-get-hash: ### Get short commit hash - optional: COMMIT=[commit, defaults to HEAD]
	git rev-parse --short $(or $(COMMIT), HEAD) 2> /dev/null || echo unknown

git-commit-get-timestamp: ### Get commit timestamp - optional: COMMIT=[commit, defaults to HEAD]
	TZ=UTC git show -s --format=%cd --date=format-local:%Y%m%d%H%M%S $(or $(COMMIT), HEAD) | cat 2> /dev/null || echo unknown

# ==============================================================================

git-tag-is-release-candidate: ### Check if a commit is tagged as release candidate - optional: COMMIT=[commit, defaults to master]; return: true|false
	commit=$(or $(COMMIT), master)
	(git show-ref --tags -d | grep $$(git rev-parse $$commit) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -- -rc$$) > /dev/null 2>&1 && echo true || echo false

git-tag-is-environment-deployment: ### Check if a commit is tagged as environment deployment - mandatory: PROFILE=[profile name]; optional: COMMIT=[commit, defaults to master]; return: true|false
	commit=$(or $(COMMIT), master)
	(git show-ref --tags -d | grep $$(git rev-parse $$commit) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -- -$(PROFILE)$$) > /dev/null 2>&1 && echo true || echo false

git-tag-create-release-candidate: ### Tag release candidate as `[YYYYmmddHHMMSS]-rc` - optional: COMMIT=[commit, defaults to master]
	commit=$(or $(COMMIT), master)
	tag=$$(date --date=$(BUILD_DATE) -u +%Y%m%d%H%M%S)-rc
	git tag $$tag $$commit
	git push origin $$tag

git-tag-create-environment-deployment: ### Tag environment deployment as `[YYYYmmddHHMMSS]-[env]` - mandatory: PROFILE=[profile name]; optional: COMMIT=[release candidate tag name, defaults to master]
	[ $(PROFILE) = local ] && (echo "ERROR: Please, specify the PROFILE"; exit 1)
	commit=$(or $(COMMIT), master)
	if [ $$(make git-tag-is-release-candidate COMMIT=$$commit) = true ]; then
		tag=$$(date --date=$(BUILD_DATE) -u +%Y%m%d%H%M%S)-$(PROFILE)
		git tag $$tag $$commit
		git push origin $$tag
	fi

git-tag-get-release-candidate: ### Get the latest release candidate tag for the whole repository or just the specified commit - optional: COMMIT=[commit]
	if [ -z "$(COMMIT)" ]; then
		git show-ref --tags -d | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -- -rc$$ | sort -r | head -n 1
	else
		git show-ref --tags -d | grep ^$$(git rev-parse --short $(COMMIT)) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -- -rc$$ | sort -r | head -n 1
	fi

git-tag-get-environment-deployment: ### Get the latest environment deployment tag for the whole repository or just the specified commit - mandatory: PROFILE=[profile name]; optional: COMMIT=[commit]
	[ $(PROFILE) = local ] && (echo "ERROR: Please, specify the PROFILE"; exit 1)
	if [ -z "$(COMMIT)" ]; then
		git show-ref --tags -d | grep ^$(COMMIT) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -- -$(PROFILE)$$ | sort -r | head -n 1
	else
		git show-ref --tags -d | grep ^$$(git rev-parse --short $(COMMIT)) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -- -$(PROFILE)$$ | sort -r | head -n 1
	fi

git-tag-list: ### List tags of a commit - optional: COMMIT=[commit, defaults to master],PROFILE=[profile name]
	commit=$(or $(COMMIT), master)
	tags=$$(git show-ref --tags -d | grep $$(git rev-parse $$commit) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -Eo ^[0-9]*-[a-z]*$$ ||:)
	[ $(PROFILE) != local ] && tags=$$(echo "$$tags" | grep -- -$(PROFILE)$$)
	echo "$$tags"

git-tag-clear: ### Remove tags from the specified commit - optional: COMMIT=[commit, defaults to master]
	commit=$(or $(COMMIT), master)
	for tag in $$(git show-ref --tags -d | grep $$(git rev-parse $$commit) | sed -e 's;.* refs/tags/;;' -e 's;\^{};;' | grep -Eo ^[0-9]*-[a-z]*$$); do
		git tag -d $$tag
		git push --delete origin $$tag 2> /dev/null ||:
	done

# ==============================================================================

.SILENT: \
	git-commit-get-hash \
	git-commit-get-timestamp \
	git-commit-has-changed-directory \
	git-tag-get-environment-deployment \
	git-tag-get-release-candidate \
	git-tag-is-environment-deployment \
	git-tag-is-release-candidate \
	git-tag-list
