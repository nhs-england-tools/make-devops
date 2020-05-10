test-git:
	make test-git-setup
	tests=( \
		test-git-config \
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
	mk_test "branch.autosetupmerge" "always = $$(git config branch.autosetupmerge)"
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
	mk_test ".git/hooks/pre-commit" "-x $(PROJECT_DIR)/.git/hooks/pre-commit"
	mk_test_complete
