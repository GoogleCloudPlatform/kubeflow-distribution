build_dir?=./build

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
