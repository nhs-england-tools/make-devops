test-git:
	make test-git-setup
	tests=( \
		test-git-config \
		test-git-check-if-branch-name-is-correct \
		test-git-secrets-load \
		test-git-secrets-add-banned \
		test-git-secrets-add-allowed \
		test-git-secrets-scan-repo-history \
		test-git-secrets-scan-repo-files \
		test-git-check-if-commit-changed-directory \
		test-git-commit-get-hash \
		test-git-commit-get-timestamp \
		test-git-commit-get-message \
		test-git-tag-is-environment-deployment \
		test-git-tag-create-environment-deployment \
		test-git-tag-get-environment-deployment \
		test-git-tag-list \
		test-git-tag-clear \
	)
	for test in $${tests[*]}; do
		mk_test_initialise $$test
		make $$test
	done
	make test-git-teardown

test-git-setup:
	:

test-git-teardown:
	:

# ==============================================================================

test-git-config:
	# act
	make git-config
	# assert
	mk_test "branch.autosetupmerge" "false = $$(git config branch.autosetupmerge)"
	mk_test "branch.autosetuprebase" "always = $$(git config branch.autosetuprebase)"
	mk_test "commit.gpgsign" "true = $$(git config commit.gpgsign)"
	mk_test "core.autocrlf" "input = $$(git config core.autocrlf)"
	mk_test "core.filemode" "true = $$(git config core.filemode)"
	mk_test "core.hidedotfiles" "false = $$(git config core.hidedotfiles)"
	mk_test "core.hooksPath" "$(GITHOOKS_DIR_REL) = $$(git config core.hooksPath)"
	mk_test "core.ignorecase" "false = $$(git config core.ignorecase)"
	mk_test "pull.rebase" "true = $$(git config pull.rebase)"
	mk_test "push.default" "current = $$(git config push.default)"
	mk_test "push.followTags" "true = $$(git config push.followTags)"
	mk_test "rebase.autoStash" "true = $$(git config rebase.autoStash)"
	mk_test "remote.origin.prune" "true = $$(git config remote.origin.prune)"
	mk_test ".git/hooks/commit-msg" "-x $(PROJECT_DIR)/.git/hooks/commit-msg"
	mk_test ".git/hooks/pre-commit" "-x $(PROJECT_DIR)/.git/hooks/pre-commit"
	mk_test ".git/hooks/prepare-commit-msg" "-x $(PROJECT_DIR)/.git/hooks/prepare-commit-msg"
	mk_test "secrets.providers git secrets --aws-provider" "0 -lt $$(git-secrets --list | grep 'secrets.providers git secrets --aws-provider' | wc -l)"
	mk_test_complete

test-git-check-if-branch-name-is-correct:
	mk_test_skip

test-git-secrets-load:
	mk_test_skip

test-git-secrets-add-banned:
	mk_test_skip

test-git-secrets-add-allowed:
	mk_test_skip

test-git-secrets-scan-repo-history:
	# act
	make git-secrets-scan-repo-history ||:
	# assert
	mk_test "0 -eq $$?"

test-git-secrets-scan-repo-files:
	# act
	make git-secrets-scan-repo-files
	# assert
	mk_test "0 -eq $$?"

test-git-check-if-commit-changed-directory:
	# act
	output=$$(make git-check-if-commit-changed-directory DIR=build/automation/tmp)
	# assert
	mk_test "false == $$output"

test-git-commit-get-hash:
	mk_test_skip

test-git-commit-get-timestamp:
	mk_test_skip

test-git-commit-get-message:
	mk_test_skip

test-git-tag-is-environment-deployment:
	mk_test_skip

test-git-tag-create-environment-deployment:
	mk_test_skip

test-git-tag-get-environment-deployment:
	mk_test_skip

test-git-tag-list:
	mk_test_skip

test-git-tag-clear:
	mk_test_skip
