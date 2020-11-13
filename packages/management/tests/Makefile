# NAME, LOCATION, PROJECT in Kptfile are set by calling kpt cfg set
#
# NAME: The cluster name of the management cluster. Warning, it should be different
#   from your Kubeflow cluster.
# LOCATION: Location of the management cluster. You can choose either regional or zonal.
# PROJECT: Google Cloud project where this management cluster is created in.
NAME=kf-mgmt-1
LOCATION=asia-east1-c
PROJECT=gongyuan-pipeline-test
MANAGED_PROJECT=gongyuan-pipeline-test
BUCKET=gongyuan-test-5

MANAGEMENT_URL=https://github.com/kubeflow/gcp-blueprints.git/management@v1.1.0
DIR=$(NAME)

.PHONY: get-pkg
get-pkg:
	rm -rf $(DIR)
	mkdir -p $(DIR)
	kpt pkg get $(MANAGEMENT_URL) $(DIR)
	cd $(DIR)/management && make get-pkg

.PHONY: set-values
set-values:
	kpt cfg set $(DIR)/instance name $(NAME)
	kpt cfg set $(DIR)/instance location $(LOCATION)
	kpt cfg set $(DIR)/instance gcloud.core.project $(PROJECT)

	kpt cfg set $(DIR)/upstream/management name $(NAME)
	kpt cfg set $(DIR)/upstream/management location $(LOCATION)
	kpt cfg set $(DIR)/upstream/management gcloud.core.project $(PROJECT)

.PHONY: apply-cluster
apply-cluster:
	cd $(DIR)/management && make apply

.PHONY: create-ctxt
create-ctxt:
	cd $(DIR)/management && make create-ctxt

.PHONY: apply-kcc
apply-kcc:
	cd $(DIR)/management && make apply-kcc

.PHONY: apply-managed-project
apply-managed-project:
	kpt cfg set $(DIR)/management/instance managed-project $(MANAGED_PROJECT)
	anthoscli apply -f $(DIR)/management/instance/managed-project/iam.yaml

.PHONY: create-bucket
create-bucket:
	kubectl create -f storagebucket.yaml

.PHONY: verify-bucket
verify-bucket:
	gsutil ls gs://$(BUCKET)

.PHONY: cluster
cluster: get-pkg set-values apply-cluster

.PHONY: manage-project
manage-project: create-ctxt apply-kcc apply-managed-project

.PHONY: bucket
bucket: create-bucket verify-bucket
