K8S_APP_NAMESPACE = $(PROJECT_GROUP_SHORT)-$(PROFILE)
K8S_DIR := $(or $(K8S_DIR), deployment/stacks)
K8S_JOB_NAMESPACE = $(PROJECT_GROUP_SHORT)-job-$(PROFILE)
K8S_KUBECONFIG_FILE = $(or $(TEXAS_K8S_KUBECONFIG_FILE), kubeconfig-lk8s-$(PROFILE)/cluster_kubeconfig)
K8S_TTL_LENGTH := $(or $(K8S_TTL_LENGTH), 2 days)

# ==============================================================================

k8s-deploy: ### Deploy application to the Kubernetes cluster - mandatory: STACK=[name],PROFILE=[name]
	make k8s-replace-variables STACK=$(STACK) PROFILE=$(PROFILE)
	eval "$$(make -s k8s-kubeconfig-export)"
	kubectl apply -k $$(make -s _k8s-get-deployment-directory)
	make k8s-clean # TODO: Create a flag to switch it off
	make k8s-sts

k8s-undeploy: ### Remove Kubernetes resources
	eval "$$(make -s k8s-kubeconfig-export)"
	if kubectl get namespaces | grep -o "$(K8S_APP_NAMESPACE) "; then
		kubectl delete namespace $(K8S_APP_NAMESPACE)
	fi

k8s-deploy-job: ### Deploy job to the Kubernetes cluster - mandatory: STACK=[name],PROFILE=[name]
	make k8s-replace-variables STACK=$(STACK) PROFILE=$(PROFILE)
	eval "$$(make -s k8s-kubeconfig-export)"
	kubectl delete jobs --all -n $(K8S_JOB_NAMESPACE)
	kubectl apply -k $$(make -s _k8s-get-deployment-directory)
	make k8s-clean # TODO: Create a flag to switch it off
	make k8s-job
	make k8s-wait-for-job-to-complete

k8s-undeploy-job: ### Remove Kubernetes resources from job namespace
	eval "$$(make -s k8s-kubeconfig-export)"
	if kubectl get namespaces | grep -o "$(K8S_JOB_NAMESPACEss) "; then
		kubectl delete namespace $(K8S_JOB_NAMESPACE)
	fi

k8s-replace-variables: ### Replace variables in base and overlay of a stack - mandatory: STACK=[name],PROFILE=[name]
	function replace_variables {
		file=$$1
		for str in $$(cat $$file | grep -Eo "[A-Za-z0-9_]*_TO_REPLACE" | sort | uniq); do
			key=$$(cut -d "=" -f1 <<<"$$str" | sed "s/_TO_REPLACE//g")
			value=$$(echo $$(eval echo "\$$$$key"))
			[ -z "$$value" ] && echo "WARNING: Variable $$key has no value" || sed -i \
				"s;$${key}_TO_REPLACE;$${value//&/\\&};g" \
				$$file ||:
		done
	}
	rsync -rav \
		--include=*.yaml \
		$(K8S_DIR)/$(STACK)/base/template/* \
		$(K8S_DIR)/$(STACK)/base
	if [ -d $(K8S_DIR)/$(STACK)/overlays/$(PROFILE)/template ]; then
		rsync -rav \
			--include=*.yaml \
			$(K8S_DIR)/$(STACK)/overlays/$(PROFILE)/template/* \
			$(K8S_DIR)/$(STACK)/overlays/$(PROFILE)
	fi
	files=(
		$$(find $(K8S_DIR)/$(STACK)/base -type f -name '*.yaml' -print | grep -v "/template/")
		$$(find $(K8S_DIR)/$(STACK)/overlays/$(PROFILE) -type f -name '*.yaml' -print 2> /dev/null | grep -v "/template/" ||:)
	)
	export K8S_TTL=$$(make k8s-get-namespace-ttl)
	for file in $${files[@]}; do
		replace_variables $$file
	done

k8s-get-namespace-ttl: ### Get the length of time for the namespace to live
	date -u +"%d-%b-%Y" -d "+$(K8S_TTL_LENGTH)"

k8s-kubeconfig-get: ### Get configuration file
	mkdir -p $(HOME)/etc
	make aws-s3-download \
		URI=$(K8S_KUBECONFIG_FILE) \
		FILE=/tmp/etc/lk8s-$(AWS_ACCOUNT_NAME)-kubeconfig

k8s-kubeconfig-export: ### Export configuration file
	echo "export KUBECONFIG=$(HOME)/etc/lk8s-$(AWS_ACCOUNT_NAME)-kubeconfig"

k8s-clean: ### Clean Kubernetes files
	find $(K8S_DIR) -type f -name '*.yaml' -print | grep -v "/template/" | xargs rm -fv
	find $(K8S_DIR)/$(STACK)/base ! -path $(K8S_DIR)/$(STACK)/base -type d -print | \
		grep -v "/template" | \
		xargs rm -rfv

# ==============================================================================

_k8s-get-deployment-directory:
	if [ -d $(K8S_DIR)/$(STACK)/overlays/$(PROFILE) ]; then
		echo $(K8S_DIR)/$(STACK)/overlays/$(PROFILE)
	else
		echo $(K8S_DIR)/$(STACK)/base
	fi

# ==============================================================================

.SILENT: \
	_k8s-get-deployment-directory \
	k8s-get-namespace-ttl \
	k8s-kubeconfig-export

# ==============================================================================

k8s-cnf: ### Show configmaps
	echo
	kubectl get configmaps \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)" \
		--output json
	echo

k8s-log: ### Show logs
	echo
	kubectl logs \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)" \
		--max-log-requests=20 \
		--all-containers=true \
		--since=60s \
		--follow=true
	echo

k8s-net: ### Show network policies
	echo
	kubectl describe networkpolicies \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)"
	echo

k8s-sts: ### Show status of pods and services
	echo -e "\nDisplay namespaces"
	kubectl get namespace \
		--selector "project-group=$(PROJECT_GROUP_SHORT)" \
		--show-labels
	echo -e "\nDisplay configmaps"
	kubectl get configmaps \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)"
	echo -e "\nDisplay networkpolicies"
	kubectl get networkpolicies \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)"
	echo -e "\nDisplay pods"
	kubectl get pods \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)" \
		--output wide
	echo -e "\nDisplay services"
	kubectl get services \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)"
	echo -e "\nDisplay events"
	kubectl get events \
		--namespace=$(K8S_APP_NAMESPACE)

# ==============================================================================

k8s-wait-for-job-to-complete: ### Wait for the job to complete
	count=1
	until [ $$count -gt 20 ]; do
		if [ "$$(make -s k8s-job-failed | tr -d '\n')" == "True" ]; then
			echo "The job has failed"
			exit 1
		fi
		if [ "$$(make -s k8s-job-complete | tr -d '\n')" == "True" ]; then
			echo "The job has completed"
			exit 0
		fi
		echo "Still waiting for the job to complete"
		sleep 5
		((count++))
	done
	echo "The job has not completed, but have given up waiting."
	exit 1

k8s-job-log: ### Show the job pod logs
	echo
	kubectl logs $$(make -s k8s-job-pod) \
		--namespace=$(K8S_JOB_NAMESPACE)

k8s-job-pod: ### Get the name of the pod created by the job
	echo
	kubectl get pods \
		--namespace=$(K8S_JOB_NAMESPACE) \
		--selector "env=$(PROFILE)" \
		--output jsonpath='{.items..metadata.name}'

k8s-job-name: ### Get the name of the job
	echo
	kubectl get jobs \
		--namespace=$(K8S_JOB_NAMESPACE) \
		--selector "env=$(PROFILE)" \
		--output jsonpath='{.items..metadata.name}'

k8s-job-failed: ### Show whether the job failed
	echo
	kubectl get jobs $$(make -s k8s-job-name)\
		--namespace=$(K8S_JOB_NAMESPACE) \
		--output jsonpath='{.status.conditions[?(@.type=="Failed")].status}'

k8s-job-complete: ### Show whether the job completed
	echo
	kubectl get jobs $$(make -s k8s-job-name)\
		--namespace=$(K8S_JOB_NAMESPACE) \
		--output jsonpath='{.status.conditions[?(@.type=="Complete")].status}'

k8s-job: ### Show status of jobs
	echo -e "\nDisplay namespaces"
	kubectl get namespace \
		--selector "project-group=$(PROJECT_GROUP_SHORT)" \
		--show-labels
	echo -e "\nDisplay configmaps"
	kubectl get configmaps \
		--namespace=$(K8S_JOB_NAMESPACE) \
		--selector "env=$(PROFILE)"
	echo -e "\nDisplay networkpolicies"
	kubectl get networkpolicies \
		--namespace=$(K8S_JOB_NAMESPACE) \
		--selector "env=$(PROFILE)"
	echo -e "\nDisplay pods"
	kubectl get pods \
		--namespace=$(K8S_JOB_NAMESPACE) \
		--selector "env=$(PROFILE)" \
		--output wide
	echo -e "\nDisplay jobs"
	kubectl get jobs \
		--namespace=$(K8S_JOB_NAMESPACE) \
		--selector "env=$(PROFILE)"
	echo -e "\nDisplay events"
	kubectl get events \
		--namespace=$(K8S_JOB_NAMESPACE)

# ==============================================================================

.SILENT: \
	k8s-cnf \
	k8s-log \
	k8s-sts \
	k8s-export-kubeconfig \
	k8s-get-namespace-ttl \
	k8s-job-failed \
	k8s-job-log \
	k8s-job-name \
	k8s-job-failed \
	k8s-job-complete \
	k8s-wait-for-job-to-complete
