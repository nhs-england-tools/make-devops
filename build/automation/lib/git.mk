git-config: ### Configure local git repository
	if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1; then
		git config branch.autosetupmerge always
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
		echo "build/automation/etc/githooks/pre-commit" > $(PROJECT_DIR)/.git/hooks/pre-commit
		chmod +x $(PROJECT_DIR)/.git/hooks/pre-commit
	fi
