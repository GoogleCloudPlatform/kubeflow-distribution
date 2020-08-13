ifndef NAME
	NAME=$(shell yq r ./instance/settings.yaml name)
endif

ifndef LOCATION
	LOCATION=$(shell yq r ./instance/settings.yaml location)
endif

ifndef PROJECT
	PROJECT=$(shell yq r ./instance/settings.yaml project)
endif

MGMTCTXT=$(shell yq r ./instance/settings.yaml name)

# The URL you want to fetch manifests from
MANIFESTS_URL=https://github.com/kubeflow/manifests.git/gcp/v2/management@master

# Directory where manifests should be fetched to
MANIFESTS_DIR=./upstream/management

INSTANCE_DIR=./instance

.PHONY: set-values
set-values:
	kpt cfg set ./instance name $(NAME)
	kpt cfg set ./instance location $(LOCATION)
	kpt cfg set ./instance gcloud.core.project $(PROJECT)
	
	kpt cfg set ./upstream/management name $(NAME)
	kpt cfg set ./upstream/management location $(LOCATION)
	kpt cfg set ./upstream/management gcloud.core.project $(PROJECT)

# Print out the context
.PHONY: echo
echo-ctxt:
	@echo MGMTCTXT=$(MGMTCTXT)

# Get packages
# TODO(jlewi): We should think about how we layout packages in kubeflow/manifests so
# users don't end up pulling tests or other things they don't need.
.PHONY: get-pkg
get-pkg:
	mkdir -p  ./upstream
	kpt pkg get $(MANIFESTS_URL) $(MANIFESTS_DIR)

.PHONY: apply
apply: hydrate
	anthoscli apply --project=$(PROJECT) -f .build/cluster

.PHONY: hydrate
hydrate:
	# Delete the directory so any resources that have been removed
	# from the manifests will be pruned
	rm -rf .build
	mkdir -p .build/
	mkdir -p .build/cluster
	kustomize build $(INSTANCE_DIR)/cluster -o .build/cluster


# Create a kubeconfig context for the management cluster
.PHONE: create-ctxt
create-ctxt:
	PROJECT=$(shell yq r ./instance/settings.yaml project) \
	   REGION=$(shell yq r ./instance/settings.yaml location) \
	   NAME=$(shell yq r ./instance/settings.yaml name) ./hack/create_context.sh

.PHONY: hydrate-kcc
hydrate-kcc:
	rm -rf ./.build/cnrm-install-system
	rm -rf ./.build/cnrm-install-services
	rm -rf ./.build/cnrm-install-iam
	mkdir -p ./.build/cnrm-install-system
	mkdir -p ./.build/cnrm-install-services
	mkdir -p ./.build/cnrm-install-iam
	kustomize build -o ./.build/cnrm-install-system $(INSTANCE_DIR)/cnrm-install-system
	kustomize build -o ./.build/cnrm-install-services $(INSTANCE_DIR)/cnrm-install-services
	kustomize build -o ./.build/cnrm-install-iam $(INSTANCE_DIR)/cnrm-install-iam

.PHONY: apply-kcc
apply-kcc: hydrate-kcc
	anthoscli apply -f .build/cnrm-install-services
	anthoscli apply -f .build/cnrm-install-iam
	kubectl --context=$(MGMTCTXT) apply -f .build/cnrm-install-system/~g_v1_namespace_cnrm-system.yaml
	kubectl --context=$(MGMTCTXT) apply -f .build/cnrm-install-system

# Update the upstream packages
.PHONE: update
update:
	rm -rf upstream
	make get-pkg
	make set-values
