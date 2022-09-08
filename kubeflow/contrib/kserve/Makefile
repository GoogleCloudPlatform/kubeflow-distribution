build_dir?=./build
PACKAGE_DIR?=$(shell pwd)/../..
YQ=docker run --rm -v "$(PACKAGE_DIR)/":/workdir mikefarah/yq:4
NAME=$(shell $(YQ) e '.data.name' kptconfig/kpt-setter-config.yaml)
PROJECT=$(shell $(YQ) e '.data."gcloud.core.project"' kptconfig/kpt-setter-config.yaml)

# The kubectl context for your Kubeflow cluster
KFCTXT=$(NAME)

.PHONY: apply
apply: hydrate
# Apply App kserve
	mkdir $(build_dir)/runtimes
	mv $(build_dir)/*clusterservingruntime* $(build_dir)/runtimes/
	kubectl --context=$(KFCTXT) apply -f $(build_dir)
	kubectl wait --for condition=established --timeout=30s crd/clusterservingruntimes.serving.kserve.io
	kubectl --context=$(KFCTXT) apply -f $(build_dir)/runtimes
	kubectl --context=$(KFCTXT) patch cm config-domain --namespace knative-serving --type merge -p '{"data":{"$(NAME).endpoints.$(PROJECT).cloud.goog": ""}}'

.PHONY: hydrate
hydrate:
# Hydrate App kserve
	rm -rf $(build_dir) && mkdir -p $(build_dir)
	kustomize build -o $(build_dir) ./
