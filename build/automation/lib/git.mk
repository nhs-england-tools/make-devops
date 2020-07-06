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

git-secrets-add-allowed: ### Add allowed secret pattern - mandatory: PATTERN=[allowed pattern]
	git-secrets --list | grep -q "secrets.allowed $(PATTERN)" \
		|| git config --add secrets.allowed '$(PATTERN)'

git-secrets-scan-history: ### Scan git histroy for any secrets
	git secrets --scan-history

git-commit-has-changed-directory: ### Determin if any file changed in directory - mandatory: DIR=[directory]; return: true|false
	if git diff --name-only --diff-filter=AMDR --cached HEAD^ | grep --quiet '$(DIR)'; then
		echo true
	else
		echo false
	fi

# ==============================================================================

.SILENT: \
	git-commit-has-changed-directory
