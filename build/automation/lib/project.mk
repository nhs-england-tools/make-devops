project-deploy: ### Deploy application service stack to the Kubernetes cluster - mandatory: PROFILE=[name]
	make k8s-deploy STACK=service
