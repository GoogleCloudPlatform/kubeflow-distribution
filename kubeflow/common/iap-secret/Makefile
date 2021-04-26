# The name of the context for your Kubeflow cluster
# NAME=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
# KFCTXT=$(NAME)

.PHONY: apply
apply: iap-secret

.PHONY: iap-secret
iap-secret: check-iap
	kubectl --context=$(KFCTXT) -n istio-system create secret generic kubeflow-oauth --from-literal=client_id=$(CLIENT_ID) --from-literal=client_secret=$(CLIENT_SECRET) --dry-run=client -o yaml | kubectl apply -f -

.PHONY: check-iap
check-iap:
	./check_oauth_secret.sh
