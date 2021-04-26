
.PHONY: apply
apply:
# App kfserving
	rm -rf $(build_dir) && mkdir -p $(build_dir)
	kustomize build --load-restrictor LoadRestrictionsNone -o $(build_dir) ./
	kubectl --context=$(KFCTXT) apply -f ./$(build_dir)
	kubectl --context=$(KFCTXT) patch cm config-domain --namespace knative-serving --type merge -p '{"data":{"$(NAME).endpoints.$(PROJECT).cloud.goog": ""}}'
