test-k8s: \
	test-k8s-setup \
	test-k8s-get-namespace-ttl \
	test-k8s-replace-variables \
	test-k8s-kubeconfig-get \
	test-k8s-kubeconfig-export \
	test-k8s-clean \
	test-k8s-teardown

test-k8s-setup:
	:

test-k8s-teardown:
	:

# ==============================================================================

test-k8s-get-namespace-ttl:
	# act
	ttl=$$(make k8s-get-namespace-ttl)
	# assert
	mk_test $(@) 0 -eq $$(date -d $$ttl > /dev/null 2>&1; echo $$?)

test-k8s-replace-variables:
	# act
	make k8s-replace-variables STACK=service PROFILE=live
	# assert
	cbase=$$(find $(K8S_DIR)/service/base -type f -name '*.yaml' -print | grep -v '/template/' | wc -l)
	cover=$$(find $(K8S_DIR)/service/overlays/live -type f -name '*.yaml' -print | grep -v '/template/' | wc -l)
	mk_test "$(@) base" 4 -eq $$cbase
	mk_test "$(@) overlays" 2 -eq $$cover

test-k8s-kubeconfig-get:
	mk_test_skip $(@) ||:

test-k8s-kubeconfig-export:
	# act
	export=$$(make k8s-kubeconfig-export)
	# assert
	mk_test $(@) 1 -eq $$(echo "$$export" | grep 'export KUBECONFIG=' | wc -l)

test-k8s-clean:
	# act
	make k8s-clean
	# assert
	count=$$(find $(K8S_DIR) -type f -name '*.yaml' -print | grep '/effective/' | wc -l)
	mk_test $(@) 0 -eq $$count
