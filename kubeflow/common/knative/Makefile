build_dir?=./build
PACKAGE_DIR?=$(shell pwd)/../..
NAME=$(shell docker run --rm -v "${PACKAGE_DIR}/":/workdir mikefarah/yq:4 e '.data.name' kptconfig/kpt-setter-config.yaml)

# The kubectl context for your Kubeflow cluster
KFCTXT=$(NAME)

.PHONY: hydrate
hydrate:
# Hydrate Common Knative
# It has error when trying to patch the resource downloaded from knative because it doesn't match kustomize requirement.
# Original release of knative manifest can not be patched by kustomize because of `already registered id`. For now we run kubectl directly.
	rm -rf $(build_dir) && mkdir -p $(build_dir)
	kustomize build -o $(build_dir) ./


.PHONY: apply
apply: hydrate
# Apply Common Knative
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_namespace_knative-serving.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_certificates.networking.internal.knative.dev.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_configurations.serving.knative.dev.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_images.caching.internal.knative.dev.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_ingresses.networking.internal.knative.dev.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_metrics.autoscaling.internal.knative.dev.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_podautoscalers.autoscaling.internal.knative.dev.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_revisions.serving.knative.dev.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_routes.serving.knative.dev.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_serverlessservices.networking.internal.knative.dev.yaml
	kubectl --context=${KFCTXT} apply -f ./$(build_dir)/*v1_customresourcedefinition_services.serving.knative.dev.yaml
	kubectl --context=$(KFCTXT) apply --recursive=true -f $(build_dir)
