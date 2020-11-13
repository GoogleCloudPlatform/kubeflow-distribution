# NAME, LOCATION, PROJECT in Kptfile are set by calling kpt cfg set
#
# NAME: The cluster name of the management cluster. Warning, it should be different
#   from your Kubeflow cluster.
# LOCATION: Location of the management cluster. You can choose either regional or zonal.
# PROJECT: Google Cloud project where this management cluster is created in.
#
# You can set these values by
# ```
# kpt cfg set ./instance name NAME
# kpt cfg set ./instance location LOCATION
# kpt cfg set ./instance gcloud.core.project PROJECT
# ```
# The values you set will be stored in ./instance/Kptfile, so they will be preserved.

NAME=$(shell yq r ./instance/Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
LOCATION=$(shell yq r ./instance/Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
PROJECT=$(shell yq r ./instance/Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')

MGMTCTXT=$(NAME)

# The URL you want to fetch upstream package from
MANIFESTS_URL=https://github.com/kubeflow/gcp-blueprints.git/packages/management@master

# For development, you can update the following line to point to your own branch.
# MANIFESTS_URL=https://github.com/USER/gcp-blueprints.git/packages/management@BRANCH

# Directory where manifests should be fetched to
MANIFESTS_DIR=./upstream/management

INSTANCE_DIR=./instance

# Print out the context
.PHONY: echo-ctxt
echo-ctxt:
	@echo MGMTCTXT=$(MGMTCTXT)

# Validate cluster values are changed from default dummy values
.PHONY: validate-values
validate-values:
ifeq ($(shell test "$(NAME)"     =  NAME  -o  \
                   "$(LOCATION)" =  LOCATION  -o  \
                   "$(PROJECT)"  =  PROJECT  &&  printf "true"), true)
	$(error Either of NAME, LOCATION, PROJECT values not set)
endif

# Validate NAME <= 18 characters
.PHONY: validate-name-length
validate-name-length:
ifeq ($(shell test $(shell printf "$(NAME)" | wc -c) -gt 18 && printf "true"), true)
	$(error NAME cannot exceed 18 characthers in length. Got: "$(NAME)")
endif

# Get upstream packages
.PHONY: get-pkg
get-pkg:
	mkdir -p  ./upstream
	kpt pkg get $(MANIFESTS_URL) $(MANIFESTS_DIR)

# Create the cluster
.PHONY: apply
apply: hydrate
	anthoscli apply -f .build/cluster

.PHONY: set-upstream-values
set-upstream-values:
	kpt cfg set ./upstream/management name $(NAME)
	kpt cfg set ./upstream/management location $(LOCATION)
	kpt cfg set ./upstream/management gcloud.core.project $(PROJECT)

.PHONY: hydrate
hydrate: validate-values set-upstream-values
	# Delete the directory so any resources that have been removed
	# from the manifests will be pruned
	rm -rf .build
	mkdir -p .build/
	mkdir -p .build/cluster
	kustomize build $(INSTANCE_DIR)/cluster -o .build/cluster

# Create a kubeconfig context for the cluster
.PHONY: create-ctxt
create-ctxt: validate-values
	PROJECT=$(PROJECT) \
	   REGION=$(LOCATION) \
	   NAME=$(NAME) ./hack/create_context.sh

.PHONY: hydrate-kcc
hydrate-kcc: validate-values set-upstream-values
	rm -rf ./.build/cnrm-install-system
	rm -rf ./.build/cnrm-install-services
	rm -rf ./.build/cnrm-install-iam
	mkdir -p ./.build/cnrm-install-system
	mkdir -p ./.build/cnrm-install-services
	mkdir -p ./.build/cnrm-install-iam
	kustomize build -o ./.build/cnrm-install-system $(INSTANCE_DIR)/cnrm-install-system
	kustomize build -o ./.build/cnrm-install-services $(INSTANCE_DIR)/cnrm-install-services
	kustomize build -o ./.build/cnrm-install-iam $(INSTANCE_DIR)/cnrm-install-iam

# The following steps install the config connector according to
# https://cloud.google.com/config-connector/docs/how-to/advanced-install
.PHONY: apply-kcc
apply-kcc: hydrate-kcc
	# Enable services required by config connector
	anthoscli apply -f .build/cnrm-install-services
	# Apply Google service account and workload identity binding
	anthoscli apply -f .build/cnrm-install-iam
	# Deploy Config Connector to the cluster
	# Apply and wait for the CRDs and namespaces first
	for resource in $$(find .build/cnrm-install-system -name '~g_v1_namespace_*.yaml' -o -name '*_customresourcedefinition_*.yaml'); \
	do \
		kubectl --context=$(MGMTCTXT) apply -f $$resource; \
	done
	# Apply all the resources
	kubectl --context=$(MGMTCTXT) apply -f .build/cnrm-install-system
	# Wait until config connector operator pods are ready
	kubectl wait -n configconnector-operator-system --for=condition=Ready pod --all --timeout 5m
	# Wait until config connector pods are created
	# TODO(Bobgy): is there a better way than sleep?
	sleep 60
	# Wait until config connector pods are ready
	kubectl wait -n cnrm-system --for=condition=Ready pod --all --timeout 5m

# Uninstall config connector and all cnrm resources in the cluster
# Note, this can only be used to uninstall config connector installed via operator.
# You cannot use it to uninstall the old config connector installed with Kubeflow v1.1.
.PHONY: uninstall-kcc
uninstall-kcc:
	kubectl --context=$(MGMTCTXT) delete configconnector --all

# Update the upstream packages
# Please edit MANIFESTS_URL to the desired version before running this.
.PHONY: update
update:
	rm -rf upstream
	make get-pkg
