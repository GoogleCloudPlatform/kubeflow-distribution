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

# Test 1.1.0
MANAGEMENT_URL=https://github.com/kubeflow/gcp-blueprints.git/management@v1.1.0

# For development, you can update the following line to point to your own branch.
# MANIFESTS_URL=https://github.com/USER/gcp-blueprints.git/management@BRANCH

.PHONY: test
test: 1-cluster 2-manage-project 3-bucket

.PHONY: cleanup
cleanup:
	kubectl delete ns --wait $(MANAGED_PROJECT) || echo "already deleted"
	yes | gcloud projects remove-iam-policy-binding $(MANAGED_PROJECT) \
		--member=serviceAccount:$(NAME)-cnrm-system@$(PROJECT).iam.gserviceaccount.com \
		--role=roles/owner || echo "already deleted"
	yes | gcloud --project=$(PROJECT) iam service-accounts delete \
		$(NAME)-cnrm-system@$(PROJECT).iam.gserviceaccount.com || echo "already deleted"
	yes | gcloud --project=$(PROJECT) container clusters delete \
	   --zone=$(LOCATION) $(NAME) || echo "already deleted"

.PHONY: get-pkg
get-pkg:
	rm -rf management
	kpt pkg get $(MANAGEMENT_URL) .
	cd management && make get-pkg

.PHONY: set-values
set-values:
	kpt cfg set management/instance name $(NAME)
	kpt cfg set management/instance location $(LOCATION)
	kpt cfg set management/instance gcloud.core.project $(PROJECT)

	kpt cfg set management/upstream/management name $(NAME)
	kpt cfg set management/upstream/management location $(LOCATION)
	kpt cfg set management/upstream/management gcloud.core.project $(PROJECT)

.PHONY: apply-cluster
apply-cluster:
	cd management && make apply

.PHONY: create-ctxt
create-ctxt:
	cd management && make create-ctxt

.PHONY: apply-kcc
apply-kcc:
	cd management && make apply-kcc

.PHONY: apply-managed-project
apply-managed-project:
	kpt cfg set management/instance managed-project $(MANAGED_PROJECT)
	anthoscli apply -f management/instance/managed-project/iam.yaml

.PHONY: create-bucket
apply-bucket:
	kubectl create namespace $(MANAGED_PROJECT) -oyaml --dry-run=client | kubectl apply -f -
	kubectl config set-context --current --namespace $(MANAGED_PROJECT)
	kubectl apply -f storagebucket.yaml

.PHONY: verify-bucket
verify-bucket:
	kubectl wait --for=condition=Ready --timeout=30s storagebucket $(BUCKET)
	gsutil ls gs://$(BUCKET)

.PHONY: 1-cluster
1-cluster: get-pkg set-values apply-cluster

.PHONY: 2-manage-project
2-manage-project: create-ctxt apply-kcc apply-managed-project

.PHONY: bucket
3-bucket: apply-bucket verify-bucket
