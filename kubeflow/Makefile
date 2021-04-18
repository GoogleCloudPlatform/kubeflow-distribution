# The name of the context for the management cluster
# These are read using yq from the Kptfile.
MGMTCTXT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.mgmt-ctxt".x-k8s-cli.setter.value')

# The name of the context for your Kubeflow cluster
NAME=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
LOCATION=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
PROJECT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')

KFCTXT=$(NAME)

# TODO(https://github.com/GoogleContainerTools/kpt/issues/539):
# Using a subdirectory fo the current directory breaks our ability to run kpt set .
# So as a hack we use a $(BUILD_DIR)/ directory in the parent directory.
BUILD_DIR=.build

# All Google Cloud resources must have a valid name, the most strict requirement is
# $NAME-admin must be a valid service account name, so $NAME should be no
# longer than 24 characters.
.PHONY: validate-values
validate-values:
	cluster_name_regex=^[a-z][-a-z0-9]{0,22}[a-z0-9]$$
	@if echo '$(NAME)' | egrep '$(cluster_name_regex)' >/dev/null; then \
		echo 'The kubeflow cluster name "$(NAME)" is valid.'; \
	else \
		echo 'The kubeflow cluster name "$(NAME)" may contain only lowercase alphanumerics and "-", must start with a letter and end with an alphanumeric, and no longer than 24 characters.'; \
	fi

# Validate cluster values are changed from default dummy values
ifeq ($(shell test "$(MGMTCTXT)" =  MANAGEMENT-CTXT   &&  printf "true"), true)
	$(error MGMTCTXT values not set)
endif
ifeq ($(shell test "$(NAME)"     =  KUBEFLOW-NAME  &&  printf "true"), true)
	$(error NAME values not set)
endif
ifeq ($(shell test "$(LOCATION)" =  LOCATION  &&  printf "true"), true)
	$(error LOCATION values not set)
endif
ifeq ($(shell test "$(PROJECT)"  =  PROJECT  &&  printf "true"), true)
	$(error PROJECT values not set)
endif

# Make sure the name isn't too long.
.PHONY: check-name
check-name:
	PROJECT=$(PROJECT) NAME=$(NAME) ./hack/check_domain_length.sh

.PHONY: apply-kubeflow
apply-kubeflow: validate-values check-name 
	# GCP Resources
	rm -rf $(BUILD_DIR)/gcp_config && mkdir -p $(BUILD_DIR)/gcp_config
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/gcp_config ./common/cnrm
	kubectl --context=$(MGMTCTXT) apply -f ./$(BUILD_DIR)/gcp_config

	# Wait for GCP Resources to finish.
	$(MAKE) -C common/cnrm wait-gcp

	# Create context for kubeflow cluster
	$(MAKE) -C common/cnrm create-ctxt

	# Install ASM and custom_overlay
	$(MAKE) -C common/asm install-asm
	
	# IAP secret should not be exported as resource file, so applying directly.
	$(MAKE) iap-secret

	# Kubeflow namespace
	rm -rf $(BUILD_DIR)/namespaces && mkdir -p $(BUILD_DIR)/namespaces
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/namespaces  ./common/kubeflow-namespace
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/namespaces

	# Kubeflow kubeflow-istio
	rm -rf $(BUILD_DIR)/kubeflow-istio && mkdir -p $(BUILD_DIR)/kubeflow-istio
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kubeflow-istio ./common/istio
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kubeflow-istio

	# Contrib application
	rm -rf $(BUILD_DIR)/application && mkdir -p $(BUILD_DIR)/application
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/application ./contrib/application
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/application

	$(MAKE) apply-cert-manager

	# Contrib metacontroller
	rm -rf $(BUILD_DIR)/metacontroller && mkdir -p $(BUILD_DIR)/metacontroller
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/metacontroller ./contrib/metacontroller
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/metacontroller

	# Common cloud-endpoints
	rm -rf $(BUILD_DIR)/cloud-endpoints && mkdir -p $(BUILD_DIR)/cloud-endpoints
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cloud-endpoints ./common/cloud-endpoints
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/cloud-endpoints

	# Cloud IAP and Ingress
	rm -rf $(BUILD_DIR)/iap-ingress && mkdir -p $(BUILD_DIR)/iap-ingress
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/iap-ingress  ./common/iap-ingress
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/iap-ingress

	# Common kubeflow-config
	rm -rf $(BUILD_DIR)/config-kubeflow && mkdir -p $(BUILD_DIR)/config-kubeflow
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/config-kubeflow ./common/config-kubeflow
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/config-kubeflow

	# App admission-webhook
	rm -rf $(BUILD_DIR)/admission-webhook && mkdir -p $(BUILD_DIR)/admission-webhook
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/admission-webhook ./apps/admission-webhook
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/admission-webhook

	# App centraldashboard
	rm -rf $(BUILD_DIR)/centraldashboard && mkdir -p $(BUILD_DIR)/centraldashboard
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/centraldashboard ./apps/centraldashboard
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/centraldashboard

	# Common kubeflow-roles
	rm -rf $(BUILD_DIR)/kubeflow-roles && mkdir -p $(BUILD_DIR)/kubeflow-roles
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kubeflow-roles ./common/kubeflow-roles
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kubeflow-roles

	# App jupyter: jupyter-web-app and notebook-controller
	rm -rf $(BUILD_DIR)/jupyter && mkdir -p $(BUILD_DIR)/jupyter
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/jupyter ./apps/jupyter
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/jupyter

	# App volumes-web-app
	rm -rf $(BUILD_DIR)/volumes-web-app && mkdir -p $(BUILD_DIR)/volumes-web-app
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/volumes-web-app ./apps/volumes-web-app
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/volumes-web-app

	# App tensorboards-web-app
	rm -rf $(BUILD_DIR)/tensorboards-web-app && mkdir -p $(BUILD_DIR)/tensorboards-web-app
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/tensorboards-web-app ./apps/tensorboard/tensorboards-web-app
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/tensorboards-web-app

	# App tensorboard-controller
	rm -rf $(BUILD_DIR)/tensorboard-controller && mkdir -p $(BUILD_DIR)/tensorboard-controller
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/tensorboard-controller ./apps/tensorboard/tensorboard-controller
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/tensorboard-controller

	# App profiles
	rm -rf $(BUILD_DIR)/profiles && mkdir -p $(BUILD_DIR)/profiles
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/profiles ./apps/profiles
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/profiles

	# App pytorch-job
	rm -rf $(BUILD_DIR)/pytorch-job && mkdir -p $(BUILD_DIR)/pytorch-job
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/pytorch-job ./apps/pytorch-job
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/pytorch-job

	# App tf-training
	rm -rf $(BUILD_DIR)/tf-training && mkdir -p $(BUILD_DIR)/tf-training
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/tf-training ./apps/tf-training
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/tf-training

	# App pipeline
	rm -rf $(BUILD_DIR)/pipeline && mkdir -p $(BUILD_DIR)/pipeline
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/pipeline ./apps/pipeline
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/pipeline

	$(MAKE) apply-knative 

	$(MAKE) apply-kfserving

	# Common user-namespace
	rm -rf $(BUILD_DIR)/user-namespace && mkdir -p $(BUILD_DIR)/user-namespace
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/user-namespace ./common/user-namespace
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/user-namespace

	# App katib
	rm -rf $(BUILD_DIR)/katib && mkdir -p $(BUILD_DIR)/katib
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/katib ./apps/katib
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/katib

	$(MAKE) apply-kubeflow-issuer

	# Kick the IAP pod because we will reset the policy and need to patch it.
	# TODO(https://github.com/kubeflow/gcp-blueprints/issues/14)
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=iap-enabler
	# Kick the backend updater pod, because information might be outdated after the apply.
	# https://github.com/kubeflow/gcp-blueprints/issues/160
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=backend-updater

.PHONY: apply-knative
apply-knative:
	# Common Knative
	# It has error when trying to patch the resource downloaded from knative because it doesn't match kustomize requirement.
	# Original release of knative manifest can not be patched by kustomize because of `already registered id`. For now we run kubectl directly.
	# rm -rf $(BUILD_DIR)/knative && mkdir -p $(BUILD_DIR)/knative
	# kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/knative ./common/knative
	# kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/knative
	kubectl apply -f ./common/knative/knative-0-22-0/serving-crds.yaml
	kubectl apply -f ./common/knative/knative-0-22-0/serving-core.yaml
	kubectl apply -f ./common/knative/knative-0-22-0/net-istio.yaml
	kubectl --context=$(KFCTXT) label namespace knative-serving istio.io/rev=asm-192-1 --overwrite

.PHONY: apply-kfserving
apply-kfserving:
	# App kfserving
	rm -rf $(BUILD_DIR)/kfserving && mkdir -p $(BUILD_DIR)/kfserving
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kfserving ./apps/kfserving
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kfserving
	kubectl --context=$(KFCTXT) patch cm config-domain --namespace knative-serving --type merge -p '{"data":{"$(NAME).endpoints.$(PROJECT).cloud.goog": ""}}'

.PHONY: apply-cert-manager
apply-cert-manager:
	# Common cert-manager
	rm -rf $(BUILD_DIR)/cert-manager && mkdir -p $(BUILD_DIR)/cert-manager
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cert-manager ./common/cert-manager
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/cert-manager
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager-webhook
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager-cainjector

.PHONY: apply-kubeflow-issuer
apply-kubeflow-issuer:
	# Common cert-manager kubeflow-issuer
	rm -rf $(BUILD_DIR)/kubeflow-issuer && mkdir -p $(BUILD_DIR)/kubeflow-issuer
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kubeflow-issuer ./common/cert-manager/upstream/cert-manager/kubeflow-issuer
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kubeflow-issuer


.PHONY: apply-v2
apply-v2: clean-build check-name check-iap apply-gcp wait-gcp create-ctxt apply-asm iap-secret apply-kubeflow
ifeq ($(PRIVATE_GKE),true)
	make apply-mirror
	make apply-endpoint
endif
	# Kick the IAP pod because we will reset the policy and need to patch it.
	# TODO(https://github.com/kubeflow/gcp-blueprints/issues/14)
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=iap-enabler
	# Kick the backend updater pod, because information might be outdated after the apply.
	# https://github.com/kubeflow/gcp-blueprints/issues/160
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=backend-updater

# Create the iap secret from environment variables
# TODO(jlewi): How can we test to make sure CLIENT_ID is set so we don't create an empty secret.
.PHONY: iap-secret
iap-secret: check-iap
	kubectl --context=$(KFCTXT) -n istio-system create secret generic kubeflow-oauth --from-literal=client_id=$(CLIENT_ID) --from-literal=client_secret=$(CLIENT_SECRET) --dry-run=client -o yaml | kubectl apply -f -

.PHONY: check-iap
check-iap:
	./hack/check_oauth_secret.sh
	