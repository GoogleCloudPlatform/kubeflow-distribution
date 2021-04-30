
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
BUILD_DIR=./build

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

.PHONY: apply-cnrm
apply-cnrm:
	rm -rf $(BUILD_DIR)/gcp_config && mkdir -p $(BUILD_DIR)/gcp_config
	kustomize build --load-restrictor LoadRestrictionsNone -o $(BUILD_DIR)/gcp_config ./common/cnrm
	kubectl --context=$(MGMTCTXT) apply -f ./$(BUILD_DIR)/gcp_config

components= \
common/cnrm \
common/asm \
common/kubeflow-namespace \
common/istio \
common/cert-manager \
contrib/metacontroller \
common/cloud-endpoints \
common/iap-ingress \
common/config-kubeflow \
apps/admission-webhook \
apps/centraldashboard \
common/kubeflow-roles \
apps/jupyter \
apps/volumes-web-app \
apps/tensorboard \
apps/profiles \
apps/pytorch-job \
apps/tf-training \
apps/pipeline \
common/knative \
apps/kfserving \
common/user-namespace \
apps/katib \

.PHONY: clean-build
clean-build:
	@for component in $(components) ; do \
	(BUILD_DIR=$(BUILD_DIR) ./hack/clean_build.sh -path $$component) || exit 1; \
	done

.PHONY: hydrate-all
hydrate-all: validate-values check-name 
	@for component in $(components) ; do \
	(BUILD_DIR=$(BUILD_DIR) NAME=$(NAME) KFCTXT=$(KFCTXT) LOCATION=$(LOCATION) PROJECT=$(PROJECT) ./hack/apply_component.sh -path $$component -hydrate_only) || exit 1; \
	done

.PHONY: apply-all
apply-all: validate-values check-name 
	@for component in $(components) ; do \
	(BUILD_DIR=$(BUILD_DIR) NAME=$(NAME) KFCTXT=$(KFCTXT) LOCATION=$(LOCATION) PROJECT=$(PROJECT) ./hack/apply_component.sh -path $$component) || exit 1; \
	done

	KFCTXT=$(KFCTXT) $(MAKE) -C common/iap-ingress pod-reset

# Delete gcp resources
.PHONY: delete-gcp
delete-gcp:
	kubectl	--context=$(MGMTCTXT) delete -f common/cnrm/$(BUILD_DIR)
