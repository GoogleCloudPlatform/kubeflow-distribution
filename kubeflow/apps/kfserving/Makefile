build_dir?=./build
PACKAGE_DIR?=$(shell pwd)/../..
NAME=$(shell docker run --rm -v "${PACKAGE_DIR}/":/workdir mikefarah/yq:4 e '.data.name' kptconfig/kpt-setter-config.yaml)
PROJECT=$(shell docker run --rm -v "${PACKAGE_DIR}/":/workdir mikefarah/yq:4 e '.data."gcloud.core.project"' kptconfig/kpt-setter-config.yaml)

# The kubectl context for your Kubeflow cluster
KFCTXT=$(NAME)

.PHONY: apply
apply: hydrate
# Apply App kfserving
	kubectl --context=$(KFCTXT) apply -f $(build_dir)
	kubectl --context=$(KFCTXT) patch cm config-domain --namespace knative-serving --type merge -p '{"data":{"$(NAME).endpoints.$(PROJECT).cloud.goog": ""}}'

.PHONY: hydrate
hydrate:
# Hydrate App kfserving
	rm -rf $(build_dir) && mkdir -p $(build_dir)
	kustomize build -o $(build_dir) ./
