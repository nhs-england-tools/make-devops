test-git: \
	test-git-config

# ==============================================================================

test-git-config:
	# act
	make git-config
	# assert
	mk_test "$(@) commit.gpgsign" true = $$(git config --local commit.gpgsign)
	mk_test "$(@) core.autocrlf" input = $$(git config --local core.autocrlf)
	mk_test "$(@) core.filemode" true = $$(git config --local core.filemode)
	mk_test "$(@) core.hidedotfiles" false = $$(git config --local core.hidedotfiles)
	mk_test "$(@) core.hooksPath" $(GITHOOKS_DIR_REL) = $$(git config --local core.hooksPath)
	mk_test "$(@) core.ignorecase" false = $$(git config --local core.ignorecase)
	mk_test "$(@) pull.rebase" true = $$(git config --local pull.rebase)
	mk_test "$(@) push.default" current = $$(git config --local push.default)
	mk_test "$(@) push.followTags" true = $$(git config --local push.followTags)
	mk_test "$(@) rebase.autoStash" true = $$(git config --local rebase.autoStash)
	mk_test "$(@) remote.origin.prune" true = $$(git config --local remote.origin.prune)
