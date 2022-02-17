PACKAGE_DIR?=$(shell pwd)

YQ=docker run --rm -v "$(PACKAGE_DIR)/":/workdir mikefarah/yq:4
# The name of the context for the management cluster
MGMTCTXT=$(shell $(YQ) e '.data.mgmt-ctxt' kptconfig/kpt-setter-config.yaml)

# # The name of the context for your Kubeflow cluster
NAME=$(shell $(YQ) e '.data.name' kptconfig/kpt-setter-config.yaml)
LOCATION=$(shell $(YQ) e '.data.location' kptconfig/kpt-setter-config.yaml)
PROJECT=$(shell $(YQ) e '.data."gcloud.core.project"' kptconfig/kpt-setter-config.yaml)

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


.PHONY: validate-kcc-values
validate-kcc-values:
ifndef MGMT_NAME
	$(error MGMT_NAME needs to be set)
endif
ifndef MGMT_PROJECT
	$(error MGMT_PROJECT needs to be set)
endif
ifndef KF_PROJECT
	$(error KF_PROJECT needs to be set)
endif

# Make sure the name isn't too long.
.PHONY: check-name
check-name:
	PROJECT=$(PROJECT) NAME=$(NAME) ./hack/check_domain_length.sh


# Load components to deploy from config.yaml
components=$(shell $(YQ) e '.components[]' config.yaml)


.PHONY: clean-build
clean-build:
	@for component in $(components) ; do \
	(BUILD_DIR=$(BUILD_DIR) ./hack/clean_build.sh -path $$component) || exit 1; \
	done

.PHONY: hydrate
hydrate: validate-values check-name
	@for component in $(components) ; do \
	(BUILD_DIR=$(BUILD_DIR) KFCTXT=$(KFCTXT) ./hack/apply_component.sh -path $$component -hydrate_only) || exit 1; \
	done

.PHONY: apply
apply: validate-values check-name
	@for component in $(components) ; do \
	(BUILD_DIR=$(BUILD_DIR) KFCTXT=$(KFCTXT) ./hack/apply_component.sh -path $$component) || exit 1; \
	done

	$(MAKE) -C common/iap-ingress pod-reset

.PHONY: delete
delete:
	# Delete gcp resources except managed storage
	BUILD_DIR=$(BUILD_DIR) MGMTCTXT=$(MGMTCTXT) ./hack/delete_gcp.sh


.PHONY: apply-kcc
apply-kcc: validate-kcc-values
	kubectl create namespace ${KF_PROJECT} --dry-run=client -o yaml | kubectl --context=$(MGMTCTXT) apply -f -
	./kcc/kpt-set.sh
	kubectl --context=$(MGMTCTXT) apply -f ./kcc/kcc-namespace