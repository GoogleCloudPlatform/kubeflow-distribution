# NAME, LOCATION, PROJECT in Kptfile are set by calling `kpt cfg set`, for
# details please read README.md.

# Read values set by `kpt cfg set`.
NAME=$(shell yq r ./instance/Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
LOCATION=$(shell yq r ./instance/Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
PROJECT=$(shell yq r ./instance/Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')

export MGMTCTXT=$(NAME)

# The URL you want to fetch upstream package from
PACKAGE_URL?=https://github.com/kubeflow/gcp-blueprints.git/packages/management@v1.2.1

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

.PHONY: validate-values
validate-values:
# Validate kpt setter values have been set
ifeq ($(shell test "$(NAME)"     =  NAME  -o  \
                   "$(LOCATION)" =  LOCATION  -o  \
                   "$(PROJECT)"  =  PROJECT  &&  printf "true"), true)
	$(error Either of NAME, LOCATION, PROJECT values not set. Please set them via command `kpt cfg set`.)
endif
# Validate NAME <= 18 characters
ifeq ($(shell test $(shell printf "$(NAME)" | wc -c) -gt 18 && printf "true"), true)
	$(error NAME cannot exceed 18 characthers in length. Got: "$(NAME)")
endif

.PHONY: apply-cluster
apply-cluster: hydrate-cluster
	$(MAKE) -f $(PACKAGE_DIR)/Makefile apply-cluster

.PHONY: hydrate-cluster
hydrate-cluster: validate-values
	$(MAKE) -f $(PACKAGE_DIR)/Makefile hydrate-cluster

.PHONY: create-context
create-context: hydrate-cluster
	$(MAKE) -f $(PACKAGE_DIR)/Makefile create-context

.PHONY: hydrate-kcc
hydrate-kcc: validate-values
	$(MAKE) -f $(PACKAGE_DIR)/Makefile hydrate-kcc

.PHONY: apply-kcc
apply-kcc: hydrate-kcc
	$(MAKE) -f $(PACKAGE_DIR)/Makefile apply-kcc

.PHONY: delete-cluster
delete-cluster: validate-values
	$(MAKE) -f $(PACKAGE_DIR)/Makefile delete-cluster

.PHONY: uninstall-kcc
uninstall-kcc:
	$(MAKE) -f $(PACKAGE_DIR)/Makefile uninstall-kcc

.PHONY: clean
clean:
	$(MAKE) -f $(PACKAGE_DIR)/Makefile clean

.PHONY: update
update:
	# Update the upstream packages to PACKAGE_URL.
	# Please edit PACKAGE_URL to the desired version before running this.
	rm -rf upstream
	$(MAKE) get-pkg
	@echo 'Warning: values in upstream packages have been reset after updating.'
	@echo 'You should run: `kpt cfg set -R` commands again to set values.'
