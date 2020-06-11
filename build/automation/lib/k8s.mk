K8S_APP_NAMESPACE = $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)-$(PROFILE)
K8S_DIR = $(PROJECT_DIR)/deployment/stacks
K8S_DIR_REL = $(shell echo $(K8S_DIR) | sed "s;$(PROJECT_DIR);;g")
K8S_JOB_NAMESPACE = $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)-$(PROFILE)-job
K8S_KUBECONFIG_FILE = $(or $(TEXAS_K8S_KUBECONFIG_FILE), kubeconfig-lk8s-$(PROFILE)/cluster_kubeconfig)
K8S_TTL_LENGTH = $(or $(TEXAS_K8S_TTL_LENGTH), 2 days)

# ==============================================================================

k8s-create-base-from-template: ### Create Kubernetes base deployment from template - optional: STACK=[name]
	stack=$(or $(STACK), default)
	mkdir -p $(DEPLOYMENT_DIR)/stacks/$$stack
	cp -rfv $(LIB_DIR)/k8s/template/deployment/stacks/stack/base $(DEPLOYMENT_DIR)/stacks/$$stack
	make -s file-replace-variables-in-dir \
		DIR=$(DEPLOYMENT_DIR)/stacks/$$stack/base \
		SUFFIX=_TEMPLATE_TO_REPLACE
	find $(DEPLOYMENT_DIR)/stacks/$$stack/base -type d -name '*_TEMPLATE_TO_REPLACE' -print0 | xargs -0 rm -rf
	cp -fv $(LIB_DIR)/k8s/template/deployment/stacks/.gitignore $(DEPLOYMENT_DIR)/stacks

k8s-create-overlay-from-template: ### Create Kubernetes overlay deployment from template - mamdatory: PROFILE=[name]; optional: STACK=[name]
	stack=$(or $(STACK), default)
	mkdir -p $(DEPLOYMENT_DIR)/stacks/$$stack
	cp -rfv $(LIB_DIR)/k8s/template/deployment/stacks/stack/overlays $(DEPLOYMENT_DIR)/stacks/$$stack
	make -s file-replace-variables-in-dir \
		DIR=$(DEPLOYMENT_DIR)/stacks/$$stack/overlays \
		SUFFIX=_TEMPLATE_TO_REPLACE
	find $(DEPLOYMENT_DIR)/stacks/$$stack/overlays -type d -name '*_TEMPLATE_TO_REPLACE' -print0 | xargs -0 rm -rf
	cp -fv $(LIB_DIR)/k8s/template/deployment/stacks/.gitignore $(DEPLOYMENT_DIR)/stacks

# ==============================================================================

k8s-deploy: ### Deploy application to the Kubernetes cluster - mandatory: STACK=[name],PROFILE=[name]
	# set up
	eval "$$(make aws-assume-role-export-variables)"
	make k8s-kubeconfig-get
	eval "$$(make k8s-kubeconfig-export-variables)"
	# deploy
	make k8s-replace-variables STACK=$(STACK) PROFILE=$(PROFILE)
	kubectl apply -k $$(make -s _k8s-get-deployment-directory)
	make k8s-clean # TODO: Create a flag to switch it off
	make k8s-sts

k8s-undeploy: ### Remove Kubernetes resources
	# set up
	eval "$$(make aws-assume-role-export-variables)"
	make k8s-kubeconfig-get
	eval "$$(make k8s-kubeconfig-export-variables)"
	# undeploy
	if kubectl get namespaces | grep -o "$(K8S_APP_NAMESPACE) "; then
		kubectl delete namespace $(K8S_APP_NAMESPACE)
	fi

k8s-deploy-job: ### Deploy job to the Kubernetes cluster - mandatory: STACK=[name],PROFILE=[name]
	# set up
	eval "$$(make aws-assume-role-export-variables)"
	make k8s-kubeconfig-get
	eval "$$(make k8s-kubeconfig-export-variables)"
	# deploy
	make k8s-replace-variables STACK=$(STACK) PROFILE=$(PROFILE)
	kubectl delete jobs --all -n $(K8S_JOB_NAMESPACE)
	kubectl apply -k $$(make -s _k8s-get-deployment-directory)
	make k8s-clean # TODO: Create a flag to switch it off
	make k8s-job
	make k8s-wait-for-job-to-complete

k8s-undeploy-job: ### Remove Kubernetes resources from job namespace
	# set up
	eval "$$(make aws-assume-role-export-variables)"
	make k8s-kubeconfig-get
	eval "$$(make k8s-kubeconfig-export-variables)"
	# undeploy
	if kubectl get namespaces | grep -o "$(K8S_JOB_NAMESPACEss) "; then
		kubectl delete namespace $(K8S_JOB_NAMESPACE)
	fi

k8s-alb-get-ingress-endpoint: ### Get ALB ingress enpoint - mandatory: PROFILE=[name]
	# set up
	eval "$$(make aws-assume-role-export-variables)"
	make k8s-kubeconfig-get
	eval "$$(make k8s-kubeconfig-export-variables)"
	# get ingress endpoint
	kubectl get ingress \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector="env=$(PROFILE)" \
		--output=json \
	| make -s docker-run-tools CMD="jq -rf $(JQ_DIR)/k8s-alb-get-ingress-endpoint.jq"

# ==============================================================================

k8s-replace-variables: ### Replace variables in base and overlay of a stack - mandatory: STACK=[name],PROFILE=[name]
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
		make file-replace-variables FILE=$$file
	done

k8s-get-namespace-ttl: ### Get the length of time for the namespace to live
	date -u +"%d-%b-%Y" -d "+$(K8S_TTL_LENGTH)"

k8s-kubeconfig-get: ### Get configuration file - mandatory: PROFILE=[name]
	mkdir -p $(HOME)/etc
	make aws-s3-download \
		URI=$(K8S_KUBECONFIG_FILE) \
		FILE=/tmp/etc/lk8s-$(AWS_ACCOUNT_NAME)-kubeconfig
	if [ $(PROFILE) == "local" ]; then
		mkdir -p $(HOME)/.kube/configs
		cp -f \
			$(HOME)/etc/lk8s-$(AWS_ACCOUNT_NAME)-kubeconfig \
			$(HOME)/.kube/configs/lk8s-$(AWS_ACCOUNT_NAME)-kubeconfig
	fi

k8s-kubeconfig-export-variables k8s-kubeconfig-export: ### Export configuration file - mandatory: PROFILE=[name]
	echo "export KUBECONFIG=$(HOME)/etc/lk8s-$(AWS_ACCOUNT_NAME)-kubeconfig"

k8s-clean: ### Clean Kubernetes files - mandatory: STACK=[name]
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
# TODO: This section needs a review

k8s-cnf: ### Show configmaps
	eval "$$(make k8s-kubeconfig-export-variables)"
	echo
	kubectl get configmaps \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)" \
		--output json
	echo

k8s-log: ### Show logs
	eval "$$(make k8s-kubeconfig-export-variables)"
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
	eval "$$(make k8s-kubeconfig-export-variables)"
	echo
	kubectl describe networkpolicies \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)"
	echo

k8s-sts: ### Show status of pods and services
	eval "$$(make k8s-kubeconfig-export-variables)"
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
	echo -e "\nDisplay ingress"
	kubectl get ingress \
		--namespace=$(K8S_APP_NAMESPACE) \
		--selector "env=$(PROFILE)"
	echo -e "\nDisplay events"
	kubectl get events \
		--namespace=$(K8S_APP_NAMESPACE)

# ==============================================================================
# TODO: This section needs a review

k8s-job-log: ### Show the job pod logs
	eval "$$(make k8s-kubeconfig-export-variables)"
	echo
	kubectl logs $$(make -s k8s-job-pod) \
		--namespace=$(K8S_JOB_NAMESPACE)

k8s-job-pod: ### Get the name of the pod created by the job
	eval "$$(make k8s-kubeconfig-export-variables)"
	echo
	kubectl get pods \
		--namespace=$(K8S_JOB_NAMESPACE) \
		--selector "env=$(PROFILE)" \
		--output jsonpath='{.items..metadata.name}'

k8s-job-name: ### Get the name of job - return: [job name]
	eval "$$(make k8s-kubeconfig-export-variables)"
	kubectl get jobs \
		--namespace=$(K8S_JOB_NAMESPACE) \
		--selector "env=$(PROFILE)" \
		--output jsonpath='{.items..metadata.name}'

k8s-job-failed: ### Show whether job failed - return: [true|false]
	eval "$$(make k8s-kubeconfig-export-variables)"
	kubectl get jobs $$(make -s k8s-job-name)\
		--namespace=$(K8S_JOB_NAMESPACE) \
		--output jsonpath='{.status.conditions[?(@.type=="Failed")].status}' \
	| tr '[:upper:]' '[:lower:]'

k8s-job-complete: ### Show whether job completed - return: [true|false]
	eval "$$(make k8s-kubeconfig-export-variables)"
	kubectl get jobs $$(make -s k8s-job-name)\
		--namespace=$(K8S_JOB_NAMESPACE) \
		--output jsonpath='{.status.conditions[?(@.type=="Complete")].status}' \
	| tr '[:upper:]' '[:lower:]'

k8s-wait-for-job-to-complete: ### Wait for job to complete - optional SECONDS=[number of seconds, defaults to 60]
	seconds=$(or $(SECONDS), 60)
	echo "Waiting for the job to complete in $$seconds seconds"
	count=0
	while [ $$count -lt $$seconds ]; do
		if [ true == "$$(make -s k8s-job-failed | tr -d '\n')" ]; then
			echo "ERROR: The job has failed"
			exit 1
		fi
		if [ true == "$$(make -s k8s-job-complete | tr -d '\n')" ]; then
			echo "The job has completed"
			exit 0
		fi
		sleep 1
		((count++))
	done
	echo "ERROR: The job did not complete in the given time of $$seconds seconds"
	exit 1

k8s-job: ### Show status of jobs
	eval "$$(make k8s-kubeconfig-export-variables)"
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
	_k8s-get-deployment-directory \
	k8s-cnf \
	k8s-get-namespace-ttl \
	k8s-job-complete \
	k8s-job-failed \
	k8s-job-log \
	k8s-job-name \
	k8s-kubeconfig-export \
	k8s-kubeconfig-export-variables \
	k8s-log \
	k8s-sts \
	k8s-wait-for-job-to-complete
