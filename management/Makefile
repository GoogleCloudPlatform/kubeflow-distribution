
# The kname of the context for the management cluster
# The name of the context for your Kubeflow cluster
NAME=$(shell yq r ./instance/settings.yaml name)
MGMTCTXT=$(NAME)

# The URL you want to fetch manifests from
# TODO(jlewi): Change to kubeflow/gcp-blueprints once its checked in
MANIFESTS_URL=https://github.com/jlewi/manifests.git/gcp/v2/management@blueprints

PROJECT=$(shell yq r ./instance/settings.yaml project)

# Directory where manifests should be fetched to
MANIFESTS_DIR=./upstream/management

INSTANCE_DIR=./instance
# Print out the context
.PHONY: echo
echo-ctxt:
	@echo MGMTCTXT=$(MGMTCTXT)

# Get packages
.PHONY: get-pkg
get-pkg:
	# TODO(jlewi): We should switch to using upstream kubeflow/manifests and pin
	# to a specific version
	# TODO(jlewi): We should think about how we layout packages in kubeflow/manifests so
	# users don't end up pulling tests or other things they don't need.	
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


# Create a kubeconfig context for the kubeflow cluster
.PHONE: create-ctxt
create-ctxt:
	PROJECT=$(shell yq r ./instance/settings.yaml project) \
	   REGION=$(shell yq r ./instance/settings.yaml location) \
	   NAME=$(NAME) ./hack/create_context.sh

.PHONY: hydrate-kcc
hydrate-kcc:
	rm -rf ./.build/cnrm-install-system	
	mkdir -p ./.build/cnrm-install-system	
	kustomize build -o ./.build/cnrm-install-system $(INSTANCE_DIR)/cnrm-install-system

.PHONY: apply-kcc
apply-kcc: hydrate-kcc
	kubectl --context=$(MGMTCTXT) apply -f .build/cnrm-install-system/~g_v1_namespace_cnrm-system.yaml
	kubectl --context=$(MGMTCTXT) apply -f .build/cnrm-install-system