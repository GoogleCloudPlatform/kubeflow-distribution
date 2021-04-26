build_dir?=./build

.PHONY: apply
apply: 
	rm -rf $(build_dir) && mkdir -p $(build_dir)
	kustomize build -o $(build_dir) ./
	kubectl --context=$(KFCTXT) apply -f $(build_dir)

.PHONY: pod-reset
pod-reset:
	# Kick the IAP pod because we will reset the policy and need to patch it.
	# TODO(https://github.com/kubeflow/gcp-blueprints/issues/14)
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=iap-enabler
	# Kick the backend updater pod, because information might be outdated after the apply.
	# https://github.com/kubeflow/gcp-blueprints/issues/160
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=backend-updater
