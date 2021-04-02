

# The name of the context for the management cluster
# These are read using yq from the Kptfile.
MGMTCTXT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.mgmt-ctxt".x-k8s-cli.setter.value')

# The name of the context for your Kubeflow cluster
NAME=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
LOCATION=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
PROJECT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')
PRIVATE_GKE=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.gke.private".x-k8s-cli.setter.value')

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
# MANIFESTS_URL?=https://github.com/kubeflow/manifests.git@v1.2.0
MANIFESTS_URL?=https://github.com/kubeflow/manifests.git@master

# All Google Cloud resources must have a valid name, the most strict requirement is
# $NAME-admin must be a valid service account name, so $NAME should be no
# longer than 24 characters.
cluster_name_regex=^[a-z][-a-z0-9]{0,22}[a-z0-9]$$
.PHONY: validate-values
validate-values:
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

#***********************************************************************************************************************
# Edit the values in cfg.mk specific to your deployment

.PHONY: set-values
set-values:
	$(MAKE) -f cfg.mk set-cfg-values

.PHONY: reset-values
reset-values:
	$(MAKE) -f cfg.mk reset-cfg-values

#************************************************************************************************************************
#
# Package management
#
# The rules below help fetch and update packages
#************************************************************************************************************************
# Get packages
# TODO(jlewi): We should think about how we layout packages in kubeflow/manifests so
# users don't end up pulling tests or other things they don't need.
.PHONY: get-pkg
get-pkg:
	mkdir -p  ./upstream
	# kpt pkg get auto-set currently throws some errors due to the way our configs
	# our structured, so we need to disable auto-set.
	kpt pkg get --auto-set=false $(MANIFESTS_URL) $(MANIFESTS_DIR)
	rm -rf $(MANIFESTS_DIR)/tests
	# TODO(jlewi): Package appears to cause problems for kpt. We should delete in the upstream
	# since its not needed anymore.
	# https://github.com/GoogleContainerTools/kpt/issues/539
	rm -rf $(MANIFESTS_DIR)/common/ambassador
	rm -rf $(MANIFESTS_DIR)/stacks/ibm
	rm -rf $(MANIFESTS_DIR)/stacks/openshift

.PHONY: get-gcp-blueprints-pkg
get-gcp-blueprints-pkg:
	./pull_upstream.sh

# Update the upstream packages
.PHONE: update
update:
	rm -rf upstream
	make get-pkg
	make set-values

.PHONY: install-asm-script
install-asm-script:
	mkdir -p ${APP_DIR}/asm;
	cd ${APP_DIR}/asm && { \
		curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9 > install_asm; \
		curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9.sha256 > install_asm.sha256; \
		sha256sum -c --ignore-missing install_asm.sha256; \
		chmod +x install_asm; \
		cd -;}

.PHONY: install-asm
install-asm: install-asm-script
	rm -rf ./asm/asm
	kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm@release-1.9-asm asm
	./asm/install_asm \
	--project_id ${PROJECT} \
	--cluster_name ${NAME} \
	--cluster_location ${LOCATION} \
	--mode install \
	--enable_all \
	--custom_overlay asm/asm/istio/options/iap-operator.yaml


#**************************************************************************************************************************
# Hydration
#
# The rules in this section build hydrated manifests
#**************************************************************************************************************************

# Run all the various hydration rules
.PHONY: hydrate
hydrate: clean-build validate-values hydrate-gcp hydrate-asm hydrate-kubeflow
ifeq ($(PRIVATE_GKE),true)
	make hydrate-mirror
endif
	# ignore error per https://github.com/kubeflow/gcp-blueprints/issues/37
	-kpt fn run $(BUILD_DIR)

.PHONY: hydrate-cnrm
hydrate-cnrm:
	# ***********************************************************************************
	# Hydrate cnrm
	rm -rf $(BUILD_DIR)/gcp_config
	mkdir -p $(BUILD_DIR)/gcp_config
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/gcp_config ./common/cnrm

.PHONY: apply-cnrm
apply-cnrm: hydrate-cnrm
	# Apply management resources
	kubectl --context=$(MGMTCTXT) apply -f ./$(BUILD_DIR)/gcp_config

.PHONY: hydrate-gcp
hydrate-gcp:
	# ***********************************************************************************
	# Hydrate cnrm
	rm -rf $(BUILD_DIR)/gcp_config
	mkdir -p $(BUILD_DIR)/gcp_config
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/gcp_config $(GCP_CONFIG)

.PHONY: hydrate-asm
hydrate-asm:
	#************************************************************************************
	# hydrate asm
	istioctl manifest generate -f $(MANIFESTS_DIR)/gcp/v2/asm/istio-operator.yaml -o $(BUILD_DIR)/istio

.PHONY: hydrate-namespaces
hydrate-namespaces:
	rm -rf $(BUILD_DIR)/namespaces
	mkdir -p $(BUILD_DIR)/namespaces
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/namespaces  ${KF_DIR}/namespaces

.PHONY: hydrate-kubeflow-istio
hydrate-kubeflow-istio:
	rm -rf $(BUILD_DIR)/kubeflow-istio
	mkdir -p $(BUILD_DIR)/kubeflow-istio
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kubeflow-istio $(KF_DIR)/kubeflow-istio

.PHONY: hydrate-metacontroller
hydrate-metacontroller:
	rm -rf $(BUILD_DIR)/metacontroller
	mkdir -p $(BUILD_DIR)/metacontroller
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/metacontroller $(KF_DIR)/metacontroller

.PHONY: hydrate-application
hydrate-application:
	rm -rf $(BUILD_DIR)/application
	mkdir -p $(BUILD_DIR)/application
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/application $(KF_DIR)/application

.PHONY: hydrate-cloud-endpoints
hydrate-cloud-endpoints:
	rm -rf $(BUILD_DIR)/cloud-endpoints
	mkdir -p $(BUILD_DIR)/cloud-endpoints
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cloud-endpoints $(KF_DIR)/cloud-endpoints

.PHONY: hydrate-iap-ingress
hydrate-iap-ingress:
	rm -rf $(BUILD_DIR)/iap-ingress
	mkdir -p $(BUILD_DIR)/iap-ingress
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/iap-ingress $(KF_DIR)/iap-ingress

.PHONY: hydrate-cert-manager
hydrate-cert-manager:
	rm -rf $(BUILD_DIR)/cert-manager
	mkdir -p $(BUILD_DIR)/cert-manager
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cert-manager $(KF_DIR)/cert-manager
	
	rm -rf $(BUILD_DIR)/cert-manager-crds
	mkdir -p $(BUILD_DIR)/cert-manager-crds
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cert-manager-crds $(KF_DIR)/cert-manager-crds
	
	rm -rf $(BUILD_DIR)/cert-manager-kube-system-resources
	mkdir -p $(BUILD_DIR)/cert-manager-kube-system-resources
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cert-manager-kube-system-resources $(KF_DIR)/cert-manager-kube-system-resources

.PHONY: hydrate-kubeflow-apps
hydrate-kubeflow-apps:
	rm -rf $(BUILD_DIR)/kubeflow-apps
	mkdir -p $(BUILD_DIR)/kubeflow-apps
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kubeflow-apps $(KF_DIR)/kubeflow-apps

.PHONY: hydrate-kubeflow-issuer
hydrate-kubeflow-issuer:
	rm -rf $(BUILD_DIR)/kubeflow-issuer
	mkdir -p $(BUILD_DIR)/kubeflow-issuer
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kubeflow-issuer $(KF_DIR)/kubeflow-issuer

.PHONY: hydrate-kubeflow
hydrate-kubeflow:
	#************************************************************************************
	# Hydrate kubeflow applications
	mkdir -p $(BUILD_DIR)/namespaces
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/namespaces  ${KF_DIR}/namespaces

	# TODO(Bobgy): remove application controller, add an issue link here
	mkdir -p $(BUILD_DIR)/application
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/application $(KF_DIR)/application

	# mkdir -p $(BUILD_DIR)/knative
	# kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/knative $(KF_DIR)/knative

	# TODO(Bobgy): sync with community which version to use
	mkdir -p $(BUILD_DIR)/cert-manager
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cert-manager $(KF_DIR)/cert-manager
	mkdir -p $(BUILD_DIR)/cert-manager-crds
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cert-manager-crds $(KF_DIR)/cert-manager-crds
	mkdir -p $(BUILD_DIR)/cert-manager-kube-system-resources
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cert-manager-kube-system-resources $(KF_DIR)/cert-manager-kube-system-resources

	mkdir -p $(BUILD_DIR)/cloud-endpoints
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/cloud-endpoints $(KF_DIR)/cloud-endpoints
	mkdir -p $(BUILD_DIR)/iap-ingress
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/iap-ingress $(KF_DIR)/iap-ingress

	mkdir -p $(BUILD_DIR)/kubeflow-apps
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kubeflow-apps $(KF_DIR)/kubeflow-apps
	mkdir -p $(BUILD_DIR)/kubeflow-istio
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kubeflow-istio $(KF_DIR)/kubeflow-istio
	mkdir -p $(BUILD_DIR)/metacontroller
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/metacontroller $(KF_DIR)/metacontroller

	# TODO(Bobgy): figure out what is kubeflow issuer
	mkdir -p $(BUILD_DIR)/kubeflow-issuer
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/kubeflow-issuer $(KF_DIR)/kubeflow-issuer


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
	# Kick the backend updater pod, because information might be outdated after the apply.
	# https://github.com/kubeflow/gcp-blueprints/issues/160
	kubectl --context=$(KFCTXT) -n istio-system delete pods -l service=backend-updater


.PHONY: apply-gcp-v2
apply-gcp-v2: hydrate-gcp
	# Apply management resources
	kubectl --context=$(MGMTCTXT) apply -f ./$(BUILD_DIR)/gcp_config

.PHONY: apply-gcp
apply-gcp: hydrate
	# Apply management resources
	kubectl --context=$(MGMTCTXT) apply -f ./$(BUILD_DIR)/gcp_config

.PHONY: apply-asm
apply-asm: hydrate
	# We need to apply the CRD definitions first
	kubectl --context=${KFCTXT} apply --recursive=true -f ./$(BUILD_DIR)/istio/Base/Base.yaml
	kubectl --context=${KFCTXT} apply --recursive=true -f ./$(BUILD_DIR)/istio/Base
	# TODO(jlewi): Should we use the newer version in asm/asm
	# istioctl manifest --context=${KFCTXT} apply -f ./manifests/gcp/v2/asm/istio-operator.yaml
	# TODO(jlewi): Switch to anthoscli once it supports generating manifests
	# anthoscli apply -f ./manifests/gcp/v2/asm/istio-operator.yaml

.PHONY: apply-namespaces
apply-namespaces: 
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/namespaces

.PHONY: apply-kubeflow-istio
apply-kubeflow-istio: 
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kubeflow-istio

.PHONY: apply-metacontroller
apply-metacontroller: 
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/metacontroller

.PHONY: apply-application
apply-application: 
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/application

.PHONY: apply-cloud-endpoints
apply-cloud-endpoints: 
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/cloud-endpoints

.PHONY: apply-iap-ingress
apply-iap-ingress: 
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/iap-ingress

.PHONY: apply-cert-manager
apply-cert-manager: 
	kubectl --context=$(KFCTXT) apply --validate=false -f ./$(BUILD_DIR)/cert-manager-crds
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/cert-manager-kube-system-resources
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/cert-manager
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager-webhook
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager
	kubectl --context=$(KFCTXT) -n cert-manager wait --for=condition=Available --timeout=600s deploy cert-manager-cainjector

.PHONY: apply-kubeflow-apps
apply-kubeflow-apps: 
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kubeflow-apps

.PHONY: apply-kubeflow-issuer
apply-kubeflow-issuer: 
	kubectl --context=$(KFCTXT) apply -f ./$(BUILD_DIR)/kubeflow-issuer

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
	#
	# Note, insert a * before v1_namespace, because different versions of
	# kustomize may generate slightly different file names:
	# https://github.com/kubeflow/gcp-blueprints/issues/164.
	kubectl --context=${KFCTXT} apply -f ./$(BUILD_DIR)/knative/*v1_namespace_knative-serving.yaml
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
	gcloud builds submit --async gs://kubeflow-examples/image-replicate/replicate-context.tar.gz --project $(PROJECT) --config $(BUILD_DIR)/cloudbuild.yaml --timeout=1800

apply-endpoint:
	# Per https://github.com/kubeflow/gcp-blueprints/issues/36 cloud endpoints controller won't
	# work when running on private GKE
	kfctl apply --context=$(KFCTXT) -f $(BUILD_DIR)/iap-ingress/ctl.isla.solutions_v1_cloudendpoint_$(NAME).yaml

.PHONY: deploy-gcp-resources
deploy-gcp-resources: hydrate-gcp apply-gcp-v2 wait-gcp

# Print out the context
.PHONY: echo
echo-ctxt:
	@echo MGMTCTXT=$(MGMTCTXT)
	@echo KFCTXT=$(KFCTXT)

#**************************************************************************************************
# Hydrate ACM repos
# These commands copy the configs to the appropriate acm repo
acm-gcp: hydrate-gcp
	acm-gcp: hydrate-gcp
	mkdir -p $(ACM_MGMT_REPO)/namespaces/$(PROJECT)
	cp -r $(BUILD_DIR)/gcp_config/* $(ACM_MGMT_REPO)/namespaces/$(PROJECT)
	rm -rf $(BUILD_DIR)/gcp_config

acm-kubeflow: hydrate-asm hydrate-kubeflow
	rm -rf $(ACM_KF_REPO)/cluster/*
	rm -rf $(ACM_KF_REPO)/namespaces/*
	mkdir -p $(ACM_KF_REPO)

	# Run kustomize fns to transform the configs.
	# ignore error per https://github.com/kubeflow/gcp-blueprints/issues/37
	-kpt fn run $(BUILD_DIR)/ --fn-path=$(MANIFESTS_DIR)/gcp/kustomize-fns

	python ./hack/to_acm_structure.py --source=$(BUILD_DIR) --dest=$(ACM_KF_REPO)

	cp ./hack/kube-system.namespace.yaml $(ACM_KF_REPO)/namespaces/kube-system/namespace.yaml

	# TODO(https://github.com/kubeflow/gcp-blueprints/issues/14) remove iap enabler pod
	# because it will try to patch the authentication policy.
	rm -rf $(ACM_KF_REPO)/namespaces/istio-system/apps_v1_Deployment_iap-enabler.yaml

	# Remoee build dir; since $(ACM_KF_REPO) will be checked into source control
	# BUILD_DIR is redundant
	rm -rf $(BUILD_DIR)

	# TODO(https://github.com/kubeflow/gcp-blueprints/issues/22)
	# Need to add the annotation for the service
	yq w -i $(ACM_KF_REPO)/namespaces/istio-system/v1_Service_istio-ingressgateway.yaml metadata.annotations["beta.cloud.google.com/backend-config"] '{"ports": {"http2":"iap-backendconfig"}}'

	# Bug fix for https://github.com/kubeflow/manifests/issues/1450
	yq w -i $(ACM_KF_REPO)/namespaces/cert-manager/namespace.yaml metadata.labels["control-plane"] "kubeflow"

	# Vet the repo for any errors
	-nomos vet --no-api-server-check --path=$(ACM_KF_REPO)

	echo done

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
	kubectl --context=$(KFCTXT) -n istio-system create secret generic kubeflow-oauth --from-literal=client_id=${CLIENT_ID} --from-literal=client_secret=${CLIENT_SECRET} --dry-run=client -o yaml | kubectl apply -f -

# You may override the variable by env var if you customized the deployment
# and deploy fewer or more types of resources.
# All Google Cloud resources deployed for this Kubeflow cluster has a label:
# "kf-name=$(NAME)".
GCP_RESOURCE_TYPES_TO_CHECK?=iamserviceaccount iampolicymember computeaddress containercluster
.PHONY: wait-gcp
wait-gcp:
	# Wait for all Google Cloud resources to get created and become ready.
	@set -e; \
	for resource in $(GCP_RESOURCE_TYPES_TO_CHECK); \
	do \
		echo "Waiting for $$resource resources..."; \
		kubectl --context=$(MGMTCTXT) wait --for=condition=Ready --timeout=600s "$${resource}" -l kf-name=$(NAME)  \
		|| (echo "Error: waiting for $${resource} ready timed out."; \
			echo "To troubleshoot, you can run:"; \
			echo "kubectl --context=$(MGMTCTXT) describe $${resource} -l kf-name=$(NAME)"; \
			exit 1); \
	done

# Create a kubeconfig context for the kubeflow cluster
.PHONY: create-ctxt
create-ctxt:
	PROJECT=$(PROJECT) \
	   REGION=$(LOCATION) \
	   NAME=$(NAME) ./hack/create_context.sh

# Delete gcp resources
delete-gcp:
	kubectl	--context=$(MGMTCTXT) delete -f $(BUILD_DIR)/gcp_config
