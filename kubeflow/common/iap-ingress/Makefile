build_dir?=./build
PACKAGE_DIR?=$(shell pwd)/../..
YQ=docker run --rm -v "$(PACKAGE_DIR)/":/workdir mikefarah/yq:4
NAME=$(shell $(YQ) e '.data.name' kptconfig/kpt-setter-config.yaml)
# The kubectl context for your Kubeflow cluster
KFCTXT=$(NAME)

.PHONY: hydrate
hydrate:
	rm -rf $(build_dir) && mkdir -p $(build_dir)
	kustomize build --load-restrictor LoadRestrictionsNone -o $(build_dir) ./

.PHONY: apply
apply: hydrate iap-secret
	kubectl --context=$(KFCTXT) apply -f $(build_dir)

.PHONY: iap-secret
iap-secret:
	OAUTH_NAME=$(KFCTXT) ../../hack/setup_iap_ingress.sh

.PHONY: check-iap
check-iap:
	./check_oauth_secret.sh

.PHONY: pod-reset
pod-reset:
	kubectl wait deployments/iap-enabler -n istio-system --for=condition=available --timeout=30s
	kubectl wait deployments/cloud-endpoints-enabler -n istio-system --for=condition=available --timeout=30s
	kubectl rollout status --watch --timeout=30s -n istio-system statefulset/backend-updater
	sleep 90
	# Kick the IAP pod because we will reset the policy and need to patch it.
	# TODO(https://github.com/kubeflow/gcp-blueprints/issues/14)
	kubectl --context=$(KFCTXT) -n istio-system delete deployment iap-enabler
	# Kick the backend updater pod, because information might be outdated after the apply.
	# https://github.com/kubeflow/gcp-blueprints/issues/160
	kubectl --context=$(KFCTXT) -n istio-system delete statefulset backend-updater
	# Kick the cloud-endpoints-enabler deployment
	kubectl --context=$(KFCTXT) -n istio-system delete deployment cloud-endpoints-enabler
