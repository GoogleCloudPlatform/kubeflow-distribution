
.PHONY: apply
apply:
	# Common cert-manager
	rm -rf $(build_dir) && mkdir -p $(build_dir)
	kustomize build --load-restrictor LoadRestrictionsNone -o $(build_dir) ./
# Try kpt live apply to simplify this steps.
	kubectl --context=$(KFCTXT) apply -f ./$(build_dir)/*v1_namespace_cert-manager.yaml
	kubectl --context=$(KFCTXT) apply --recursive=true -f ./$(build_dir)
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager-webhook
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager-cainjector
