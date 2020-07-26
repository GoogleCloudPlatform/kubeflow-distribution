# The kname of the context for the management cluster
# These can be read using yq from the settings file.
#
# If you don't have yq
MGMTCTXT=$(shell yq r ./instance/settings.yaml mgmt-ctxt)
# The name of the context for your Kubeflow cluster
NAME=$(shell yq r ./instance/settings.yaml name)
PROJECT=$(shell yq r ./instance/settings.yaml project)
PRIVATE_GKE=$(shell yq r ./instance/settings.yaml gkePrivate true)

KFCTXT=$(NAME)

# Path to kustomize directories
GCP_CONFIG=./instance/gcp_config
KF_DIR=./instance/kustomize

APP_DIR=.
MANIFESTS_DIR=./upstream/manifests

ACM_KF_REPO=acm-repo

# TODO(https://github.com/GoogleContainerTools/kpt/issues/539):
# Using a subdirectory fo the current directory breaks our ability to run kpt set .
# So as a hack we use a $(BUILD_DIR)/ directory in the parent directory.
BUILD_DIR=.build

# The URL you want to fetch manifests from
# TODO(jlewi): Should we make this a setter to make it easier to update programmatically?
MANIFESTS_URL=https://github.com/kubeflow/manifests.git@v1.1.0


#***********************************************************************************************************************
# Edit this section to set the values specific to your deployment

.PHONY: set-values
set-values:
	kpt cfg set ./instance gke.private false

	kpt cfg set ./instance mgmt-ctxt <YOUR_MANAGEMENT_CTXT>

	kpt cfg set ./upstream/manifests/gcp name <YOUR_KF_NAME>
	kpt cfg set ./upstream/manifests/gcp gcloud.core.project <PROJECT_TO_DEPLOY_IN>
	kpt cfg set ./upstream/manifests/gcp gcloud.compute.zone <ZONE>
	kpt cfg set ./upstream/manifests/gcp location <REGION OR ZONE>
	kpt cfg set ./upstream/manifests/gcp log-firewalls false

	kpt cfg set ./upstream/manifests/stacks/gcp name <YOUR_KF_NAME>
	kpt cfg set ./upstream/manifests/stacks/gcp gcloud.core.project <PROJECT_TO_DEPLOY_IN>

	kpt cfg set ./instance name <YOUR_KF_NAME>
	kpt cfg set ./instance location <YOUR_REGION or ZONE>
	kpt cfg set ./instance gcloud.core.project <YOUR PROJECT>
	kpt cfg set ./instance email <YOUR_EMAIL_ADDRESS>

#************************************************************************************************************************
#
# Package management
#
# The rules below help fetch and update packages
#************************************************************************************************************************
# Get packages
.PHONY: get-pkg
get-pkg:
	# TODO(jlewi): We should switch to using upstream kubeflow/manifests and pin
	# to a specific version
	# TODO(jlewi): We should think about how we layout packages in kubeflow/manifests so
	# users don't end up pulling tests or other things they don't need.
	mkdir -p  ./upstream
	# kpt pkg get currently throws some errors due to the way our configs our structured
	# so we need to ignore those and keep going.
	-kpt pkg get $(MANIFESTS_URL) $(MANIFESTS_DIR)
	rm -rf $(MANIFESTS_DIR)/tests
	# TODO(jlewi): Package appears to cause problems for kpt. We should delete in the upstream
	# since its not needed anymore.
	# https://github.com/GoogleContainerTools/kpt/issues/539
	rm -rf $(MANIFESTS_DIR)/common/ambassador


# Update the upstream packages
.PHONE: update
update:
	rm -rf upstream
	make get-pkg
	make set-values

#**************************************************************************************************************************
# Hydration
#
# The rules in this section build hydrated manifests
#**************************************************************************************************************************

# Run all the various hydration rules
.PHONY: hydrate
hydrate: clean-build hydrate-gcp hydrate-asm hydrate-kubeflow
ifeq ($(PRIVATE_GKE),true)
		make hydrate-mirror
endif
	# ignore error per https://github.com/kubeflow/gcp-blueprints/issues/37
	-kpt fn run $(BUILD_DIR)

.PHONY: hydrate-gcp
hydrate-gcp:
	# ***********************************************************************************
	# Hydrate cnrm
	mkdir -p $(BUILD_DIR)/gcp_config
	kustomize build --load_restrictor none -o $(BUILD_DIR)/gcp_config $(GCP_CONFIG)

.PHONY: hydrate-asm
hydrate-asm:
	#************************************************************************************
	# hydrate asm
	istioctl manifest generate -f $(MANIFESTS_DIR)/gcp/v2/asm/istio-operator.yaml -o $(BUILD_DIR)/istio

.PHONY: hydrate-kubeflow
hydrate-kubeflow:
	#************************************************************************************
	# Hydrate kubeflow applications
	mkdir -p $(BUILD_DIR)/namespaces
	kustomize build --load_restrictor none -o $(BUILD_DIR)/namespaces  ${KF_DIR}/namespaces

	mkdir -p $(BUILD_DIR)/application
	kustomize build --load_restrictor none -o $(BUILD_DIR)/application $(KF_DIR)/application

	mkdir -p $(BUILD_DIR)/knative
	kustomize build --load_restrictor none -o $(BUILD_DIR)/knative $(KF_DIR)/knative

	mkdir -p $(BUILD_DIR)/cert-manager
	kustomize build --load_restrictor none -o $(BUILD_DIR)/cert-manager $(KF_DIR)/cert-manager
	mkdir -p $(BUILD_DIR)/cert-manager-crds
	kustomize build --load_restrictor none -o $(BUILD_DIR)/cert-manager-crds $(KF_DIR)/cert-manager-crds
	mkdir -p $(BUILD_DIR)/cert-manager-kube-system-resources
	kustomize build --load_restrictor none -o $(BUILD_DIR)/cert-manager-kube-system-resources $(KF_DIR)/cert-manager-kube-system-resources
	mkdir -p $(BUILD_DIR)/cloud-endpoints
	kustomize build --load_restrictor none -o $(BUILD_DIR)/cloud-endpoints $(KF_DIR)/cloud-endpoints
	mkdir -p $(BUILD_DIR)/iap-ingress
	kustomize build --load_restrictor none -o $(BUILD_DIR)/iap-ingress $(KF_DIR)/iap-ingress
	mkdir -p $(BUILD_DIR)/kubeflow-apps
	kustomize build --load_restrictor none -o $(BUILD_DIR)/kubeflow-apps $(KF_DIR)/kubeflow-apps
	mkdir -p $(BUILD_DIR)/kubeflow-apps
	kustomize build --load_restrictor none -o $(BUILD_DIR)/kubeflow-istio $(KF_DIR)/kubeflow-istio
	mkdir -p $(BUILD_DIR)/metacontroller
	kustomize build --load_restrictor none -o $(BUILD_DIR)/metacontroller $(KF_DIR)/metacontroller
	mkdir -p $(BUILD_DIR)/kubeflow-issuer
	kustomize build --load_restrictor none -o $(BUILD_DIR)/kubeflow-issuer $(KF_DIR)/kubeflow-issuer


# Hydrate resources to mirror images
hydrate-mirror:
	kfctl alpha mirror build $(MANIFESTS_DIR)/experimental/mirror-images/gcp_template.yaml -d ./instance/kustomize -V -o $(BUILD_DIR)/mirror-pipeline.yaml --gcb
	mv cloudbuild.yaml $(BUILD_DIR)/

	# Transform all the images
	cp $(MANIFESTS_DIR)/gcp/v2/privateGKE/kustomize-fns/image_prefix.yaml $(BUILD_DIR)/


#*****************************************************************************************************
# Apply
#
# Rules to apply the various manifests
#****************************************************************************************************

# Uber apply rule to invoke all dependencies
# TODO(jlewi): If we use prune does that give us a complete upgrade solution?
# TODO(jlewi): Should we insert appropriate wait statements to wait for various services to
# be available before continuing?
.PHONY: apply
apply: clean-build check-name check-iap apply-gcp wait-gcp create-ctxt apply-asm apply-kubeflow iap-secret
ifeq ($(PRIVATE_GKE),true)
	make apply-mirror
	make apply-endpoint
endif
	# Kick the IAP pod because we will reset the policy and need to patch it.
	# TODO(https://github.com/kubeflow/gcp-blueprints/issues/14)
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=iap-enabler


.PHONY: apply-gcp
apply-gcp: hydrate
	# Apply management resources
	kubectl --context=$(MGMTCTXT) apply -f ./$(BUILD_DIR)/gcp_config

.PHONY: apply-services
apply-services: hydrate
	# Apply management resources
	anthoscli apply --project=$(PROJECT) -f ./instance/gcp_config/enable-services.yaml

.PHONY: apply-asm
apply-asm: hydrate
	# Initialize your project to ready it for ASM installation.
	# Reference: https://cloud.google.com/service-mesh/docs/gke-install-new-cluster#setting_credentials_and_permissions
	curl --request POST \
		--header "Authorization: Bearer `gcloud auth print-access-token`" \
		--data '' \
		--fail \
		"https://meshconfig.googleapis.com/v1alpha1/projects/$(PROJECT):initialize"
	# We need to apply the CRD definitions first
	kubectl --context=${KFCTXT} apply --recursive=true -f ./$(BUILD_DIR)/istio/Base/Base.yaml
	kubectl --context=${KFCTXT} apply --recursive=true -f ./$(BUILD_DIR)/istio/Base
	# TODO(jlewi): Should we use the newer version in asm/asm
	# istioctl manifest --context=${KFCTXT} apply -f ./manifests/gcp/v2/asm/istio-operator.yaml
	# TODO(jlewi): Switch to anthoscli once it supports generating manifests
	# anthoscli apply -f ./manifests/gcp/v2/asm/istio-operator.yaml

.PHONY: apply-kubeflow
apply-kubeflow: hydrate
	# Apply kubeflow apps
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/namespaces
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kubeflow-istio
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/metacontroller
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/application
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/cloud-endpoints
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/iap-ingress

	# Apply the namespace first
	kubectl --context=${KFCTXT} apply -f ./$(BUILD_DIR)/knative/~g_v1_namespace_knative-serving.yaml
	kubectl --context=${KFCTXT} apply --recursive=true -f ./$(BUILD_DIR)/knative

	# Due to https://github.com/jetstack/cert-manager/issues/2208
	# We need to skip validation on Kubernetes 1.14
	kubectl --context=$(KFCTXT) apply --validate=false -f ./$(BUILD_DIR)/cert-manager-crds
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/cert-manager-kube-system-resources
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/cert-manager
	# We need to wait for certmanager webhook to be available other wise we will get failures
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager-webhook
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager-cainjector
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kubeflow-apps
	# Create the kubeflow-issuer last to give cert-manager time deploy
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kubeflow-issuer

apply-mirror: hydrate-mirror
	# Per https://github.com/kubeflow/gcp-blueprints/issues/36 cloud endpoints controller won't
	# work when running on private GKE
	# TODO(jlewi): This should be changed to kfctl once the command is baked into kfctl
	# The path is also hardcoded for jlewi.
	gcloud builds submit --async gs://kubeflow-examples/image-replicate/replicate-context.tar.gz --project $(PROJECT) --config $(BUILD_DIR)/cloudbuild.yaml

apply-endpoint:
	# Per https://github.com/kubeflow/gcp-blueprints/issues/36 cloud endpoints controller won't
	# work when running on private GKE
	kfctl apply --context=$(KFCTXT) -f $(BUILD_DIR)/iap-ingress/ctl.isla.solutions_v1_cloudendpoint_$(NAME).yaml

# Print out the context
.PHONY: echo
echo-ctxt:
	@echo MGMTCTXT=$(MGMTCTXT)
	@echo KFCTXT=$(KFCTXT)

#**************************************************************************************************
# Hydrate ACM repos
# These commands copy the configs to the appropriate acm repo
acm-gcp: hydrate-gcp
	cp -r $(BUILD_DIR)/gcp_config $(ACM_MGMT_REPO)/namespaces/$(PROJECT)

acm-kubeflow: hydrate-asm hydrate-kubeflow
	rm -rf $(ACM_KF_REPO)
	mkdir -p $(ACM_KF_REPO)
	find $(BUILD_DIR) -name "*.yaml" -not -path  "*/gcp_config/**" -exec cp {} $(ACM_KF_REPO)/ ";"

#*****************************************************************************************
#
# Helpers
#
# The rules below provide various utilities and helpers to glue the steps together
#*****************************************************************************************

.PHONY: clean-build
clean-build:
	# Delete build because we want to prune any resources which are no longer defined in the manifests
	rm -rf $(BUILD_DIR)/
	mkdir -p $(BUILD_DIR)/

# Make sure the name isn't too long.
.PHONY: check-name
check-name:
	PROJECT=$(PROJECT) NAME=$(NAME) ./hack/check_domain_length.sh

.PHONY: check-iap
check-iap:
	./hack/check_oauth_secret.sh

# Create the iap secret from environment variables
# TODO(jlewi): How can we test to make sure CLIENT_ID is set so we don't create an empty secret.
.PHONY: iap-secret
iap-secret: check-iap
	kubectl --context=$(KFCTXT) -n istio-system create secret generic kubeflow-oauth --from-literal=client_id=${CLIENT_ID} --from-literal=client_secret=${CLIENT_SECRET} --dry-run -o yaml | kubectl apply -f -

.PHONY: wait-gcp
wait-gcp:
	kubectl --context=$(MGMTCTXT) wait --for=condition=Ready --timeout=600s  containercluster $(NAME)

# Create a kubeconfig context for the kubeflow cluster
.PHONY: create-ctxt
create-ctxt:
	PROJECT=$(shell yq r ./instance/settings.yaml project) \
	   REGION=$(shell yq r ./instance/settings.yaml location) \
	   NAME=$(NAME) ./hack/create_context.sh

# Delete gcp resources
delete-gcp:
	kubectl	--context=$(MGMTCTXT) delete -f $(BUILD_DIR)/gcp_config
