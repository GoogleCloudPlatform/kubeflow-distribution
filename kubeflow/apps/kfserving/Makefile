build_dir?=./build
NAME=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
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
