
# The name of the context for your Kubeflow cluster
MGMTCTXT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.mgmt-ctxt".x-k8s-cli.setter.value')
# NAME=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
# LOCATION=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
# PROJECT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')
build_dir?=./build

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
	   NAME=$(NAME) ../../hack/create_context.sh

.PHONY: hydrate
hydrate: 
	rm -rf $(build_dir) && mkdir -p $(build_dir)
	kustomize build -o $(build_dir) ./

.PHONY: apply-cnrm
apply-cnrm: hydrate
	kubectl --context=$(MGMTCTXT) apply -f $(build_dir)

.PHONY: apply
apply:
	echo $(build_dir)
	$(MAKE) apply-cnrm build_dir=$(build_dir)
	$(MAKE) wait-gcp
	$(MAKE) create-ctxt
