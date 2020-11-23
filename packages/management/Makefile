# NAME, LOCATION, PROJECT in Kptfile are set by calling kpt cfg set
#
# NAME: The cluster name of the management cluster. Warning, it should be different
#   from your Kubeflow cluster.
# LOCATION: Location of the management cluster. You can choose either regional or zonal.
# PROJECT: Google Cloud project where this management cluster is created in.
#
# You can set these values by
# ```
# kpt cfg set . name NAME
# kpt cfg set . location LOCATION
# kpt cfg set . gcloud.core.project PROJECT
# ```
# The values you set will be stored in ./Kptfile, so they will be preserved.

# Directory where manifests live. Defaults to current directory.
# When calling this makefile from a different directory, this should be
# overriden to relative path from working directory.
PACKAGE_DIR?=.
BUILD_DIR?=build
# Specific package dirs can be overriden with ./instance/xxxx paths, so that
# users can add kustomize overlays on top of the base package.
PACKAGE_CLUSTER_DIR?=$(PACKAGE_DIR)/cluster
PACKAGE_CNRM_SERVICES_DIR?=$(PACKAGE_DIR)/cnrm-install/services
PACKAGE_CNRM_IAM_DIR?=$(PACKAGE_DIR)/cnrm-install/iam
PACKAGE_CNRM_SYSTEM_DIR?=$(PACKAGE_DIR)/cnrm-install/install-system

# If MGMTCTXT kubecontext is defined, then let's use the context argument for
# kubectl commands.
ifdef MGMTCTXT
	CTXT_ARG=--context=$(MGMTCTXT)
else
	CTXT_ARG=
endif

# The values you set via `kpt cfg set` will be stored in Kptfile.
NAME=$(shell yq r $(PACKAGE_DIR)/Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
LOCATION=$(shell yq r $(PACKAGE_DIR)/Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
PROJECT=$(shell yq r $(PACKAGE_DIR)/Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')

# All Google Cloud resources must have a valid name, the most strict requirement is
# $NAME-cnrm-system must be a valid service account name, so $NAME should be no
# longer than 18 characters.
cluster_name_regex=^[a-z][-a-z0-9]{0,16}[a-z0-9]$$
.PHONY: validate-values
validate-values:
	@if echo '$(NAME)' | egrep '$(cluster_name_regex)' >/dev/null; then \
		echo 'The management cluster name "$(NAME)" is valid.'; \
	else \
		echo 'The management cluster name "$(NAME)" may contain only lowercase alphanumerics and "-", must start with a letter and end with an alphanumeric, and no longer than 18 characters.'; \
	fi

# Validate kpt setter values have been set
ifeq ($(shell test "$(NAME)"     =  NAME  -o  \
                   "$(LOCATION)" =  LOCATION  -o  \
                   "$(PROJECT)"  =  PROJECT  &&  printf "true"), true)
	$(error Either of NAME, LOCATION, PROJECT values not set. Please set them via command `kpt cfg set`.)
endif

.PHONY: hydrate-cluster
hydrate-cluster: validate-values
	# Delete the directory so any resources that have been removed
	# from the manifests will be pruned
	rm -rf $(BUILD_DIR)/cluster
	mkdir -p $(BUILD_DIR)/cluster
	kustomize build $(PACKAGE_CLUSTER_DIR) -o $(BUILD_DIR)/cluster

.PHONY: apply-cluster
apply-cluster:
	# Create the cluster
	anthoscli apply -f $(BUILD_DIR)/cluster

.PHONY: create-context
create-context: validate-values
	# Create a kubeconfig context for the cluster
	PROJECT=$(PROJECT) \
	   REGION=$(LOCATION) \
	   NAME=$(NAME) $(PACKAGE_DIR)/hack/create_context.sh

.PHONY: hydrate-kcc
hydrate-kcc: validate-values
	rm -rf ./$(BUILD_DIR)/cnrm-install-services
	rm -rf ./$(BUILD_DIR)/cnrm-install-iam
	rm -rf ./$(BUILD_DIR)/cnrm-install-system
	mkdir -p ./$(BUILD_DIR)/cnrm-install-services
	mkdir -p ./$(BUILD_DIR)/cnrm-install-iam
	mkdir -p ./$(BUILD_DIR)/cnrm-install-system
	kustomize build -o ./$(BUILD_DIR)/cnrm-install-services $(PACKAGE_CNRM_SERVICES_DIR)
	kustomize build -o ./$(BUILD_DIR)/cnrm-install-iam $(PACKAGE_CNRM_IAM_DIR)
	kustomize build -o ./$(BUILD_DIR)/cnrm-install-system $(PACKAGE_CNRM_SYSTEM_DIR)

.PHONY: apply-kcc
apply-kcc:
	# The following steps install the config connector according to
	# https://cloud.google.com/config-connector/docs/how-to/advanced-install
	# Enable services required by config connector
	anthoscli apply -f $(BUILD_DIR)/cnrm-install-services
	# Apply Google service account and workload identity binding
	anthoscli apply -f $(BUILD_DIR)/cnrm-install-iam
	# Deploy Config Connector to the cluster
	# Apply and wait for the CRDs and namespaces first
	for resource in $$(find $(BUILD_DIR)/cnrm-install-system -name '~g_v1_namespace_*.yaml' -o -name '*_customresourcedefinition_*.yaml'); \
	do \
		kubectl $(CTXT_ARG) apply -f $$resource; \
	done
	# Apply all the resources
	kubectl $(CTXT_ARG) apply -f $(BUILD_DIR)/cnrm-install-system
	# Wait until config connector operator pods are ready
	kubectl $(CTXT_ARG) wait -n configconnector-operator-system --for=condition=Ready pod --all --timeout 5m
	# Wait until config connector pods are created
	# TODO(Bobgy): is there a better way than sleep?
	sleep 60
	# Wait until config connector pods are ready
	kubectl $(CTXT_ARG) wait -n cnrm-system --for=condition=Ready pod --all --timeout 5m

.PHONY: uninstall-kcc
uninstall-kcc:
	# Uninstall config connector and all cnrm resources in the cluster.
	# Google Cloud resources managed by this config connector will be kept. You can
	# use a config connector to manage them again following https://cloud.google.com/config-connector/docs/how-to/managing-deleting-resources#acquiring_a_dataset
	# Note, this can only be used to uninstall config connector installed via operator (in Kubeflow v1.2 or after).
	# You cannot use it to uninstall the old config connector installed with Kubeflow v1.1.
	kubectl $(CTXT_ARG) delete configconnector --all

.PHONY: delete-cluster
delete-cluster: validate-values
	# Deletes management cluster GCP resources.
	# Similar to uninstall-kcc, all Google Cloud resources managed by this
	# management cluster will be kept.
	-gcloud --project=${PROJECT} iam service-accounts delete \
		${NAME}-cnrm-system@${PROJECT}.iam.gserviceaccount.com
	-gcloud --project=${PROJECT} container clusters delete \
		--region=${LOCATION} ${NAME}

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
