# NAME, LOCATION, PROJECT in Kptfile are set in ./set-values.sh
# Please edit ./set-values.sh before calling this Makefile.

NAME=$(shell yq r ./instance/Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
LOCATION=$(shell yq r ./instance/Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
PROJECT=$(shell yq r ./instance/Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')

export MGMTCTXT=$(NAME)

# The URL you want to fetch upstream package from
PACKAGE_URL=https://github.com/kubeflow/gcp-blueprints.git/packages/management@master

# For development, you can update the following line to point to your own branch.
# PACKAGE_URL=https://github.com/USER/gcp-blueprints.git/packages/management@BRANCH

INSTANCE_DIR=./instance

# Directory where packages should be read from. Export these variables, so
# recursive make commands can get them.
export PACKAGE_DIR=./upstream/management
export PACKAGE_CLUSTER_DIR=$(INSTANCE_DIR)/cluster
export PACKAGE_CNRM_SERVICES_DIR=$(INSTANCE_DIR)/cnrm-install-services
export PACKAGE_CNRM_IAM_DIR=$(INSTANCE_DIR)/cnrm-install-iam
export PACKAGE_CNRM_SYSTEM_DIR=$(INSTANCE_DIR)/cnrm-install-system

# Print out the context
.PHONY: echo-ctxt
echo-ctxt:
	@echo MGMTCTXT=$(MGMTCTXT)

# Get upstream packages
.PHONY: get-pkg
get-pkg:
	mkdir -p  ./upstream
	kpt pkg get $(PACKAGE_URL) $(PACKAGE_DIR)

.PHONY: set-values
set-values:
	# Please first edit ./set-values.sh to your own values.
	./set-values.sh

.PHONY: apply-cluster
apply-cluster: hydrate-cluster
	$(MAKE) -f $(PACKAGE_DIR)/Makefile apply-cluster create-ctxt

.PHONY: hydrate-cluster
hydrate-cluster: set-values
	$(MAKE) -f $(PACKAGE_DIR)/Makefile hydrate-cluster

.PHONY: hydrate-kcc
hydrate-kcc: set-values
	$(MAKE) -f $(PACKAGE_DIR)/Makefile hydrate-kcc

.PHONY: apply-kcc
apply-kcc: hydrate-kcc
	$(MAKE) -f $(PACKAGE_DIR)/Makefile apply-kcc

.PHONY: delete-gcp-resources
delete-gcp-resources: set-values
	$(MAKE) -f $(PACKAGE_DIR)/Makefile delete-gcp-resources

.PHONY: uninstall-kcc
uninstall-kcc:
	$(MAKE) -f $(PACKAGE_DIR)/Makefile uninstall-kcc

.PHONY: clean
clean:
	$(MAKE) -f $(PACKAGE_DIR)/Makefile clean

.PHONY: update
update:
	# Update the upstream packages
	# Please edit PACKAGE_URL to the desired version before running this.
	rm -rf upstream
	$(MAKE) get-pkg set-values
