build_dir?=./build

.PHONY: hydrate
hydrate: 
	rm -rf $(build_dir) && mkdir -p $(build_dir)
	kustomize build --load-restrictor LoadRestrictionsNone -o $(build_dir) ./

.PHONY: apply
apply: hydrate iap-secret
	kubectl --context=$(KFCTXT) apply -f $(build_dir)

.PHONY: iap-secret
iap-secret: check-iap
	kubectl --context=$(KFCTXT) -n istio-system create secret generic kubeflow-oauth --from-literal=client_id=$(CLIENT_ID) --from-literal=client_secret=$(CLIENT_SECRET) --dry-run -o yaml | kubectl apply -f -

.PHONY: check-iap
check-iap:
	./check_oauth_secret.sh

.PHONY: pod-reset
pod-reset:
	# Kick the IAP pod because we will reset the policy and need to patch it.
	# TODO(https://github.com/kubeflow/gcp-blueprints/issues/14)
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=iap-enabler
	# Kick the backend updater pod, because information might be outdated after the apply.
	# https://github.com/kubeflow/gcp-blueprints/issues/160
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=backend-updater
