# Use .env file to include environment specific parameters
include .env

GH_USER?=kubeflow
GH_REPO?=gcp-blueprints
GH_BRANCH?=master

# Test master
MANAGEMENT_URL?=https://github.com/$(GH_USER)/$(GH_REPO).git/management@$(GH_BRANCH)
PACKAGE_URL?=https://github.com/$(GH_USER)/$(GH_REPO).git/packages/management@$(GH_BRANCH)

.PHONY: test
deploy-and-test: 1-cluster 2-manage-project 3-bucket

.PHONY: cleanup
cleanup:
	kpt cfg set resources bucket BUCKET
	kubectl delete ns --wait $(MANAGED_PROJECT) || echo "already deleted"
	yes | gcloud projects remove-iam-policy-binding $(MANAGED_PROJECT) \
		--member=serviceAccount:$(NAME)-cnrm-system@$(PROJECT).iam.gserviceaccount.com \
		--role=roles/owner || echo "already deleted"
	yes | gcloud --project=$(PROJECT) iam service-accounts delete \
		$(NAME)-cnrm-system@$(PROJECT).iam.gserviceaccount.com || echo "already deleted"
	yes | gcloud --project=$(PROJECT) container clusters delete \
	   --zone=$(LOCATION) $(NAME) || echo "already deleted"

.PHONY: 1-cluster
1-cluster: get-pkg set-values apply-cluster

.PHONY: 2-manage-project
2-manage-project: create-context apply-kcc apply-managed-project

.PHONY: bucket
3-bucket: apply-bucket verify-bucket

.PHONY: get-pkg
get-pkg:
	rm -rf management
	kpt pkg get $(MANAGEMENT_URL) .
	cd management && PACKAGE_URL=$(PACKAGE_URL) make get-pkg
	# make set-values.sh an empty script, because in this test, we set values
	# directly via kpt cfg set
	echo "#!/bin/bash" > management/set-values.sh

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
	# After Kubflow v1.2, we use apply-cluster instead of apply
	cd management && (make apply-cluster || make apply)

.PHONY: create-context
create-context:
	cd management && make create-context

.PHONY: apply-kcc
apply-kcc:
	cd management && make apply-kcc

.PHONY: apply-managed-project
apply-managed-project:
	kpt cfg set management/instance managed-project $(MANAGED_PROJECT)
	anthoscli apply -f management/instance/managed-project/iam.yaml

.PHONY: create-bucket
apply-bucket:
	kubectl create namespace $(MANAGED_PROJECT) -oyaml --dry-run | kubectl apply -f -
	kubectl config set-context --current --namespace $(MANAGED_PROJECT)
	kpt cfg set resources bucket $(BUCKET)
	kubectl apply -f ./resources/storagebucket.yaml

.PHONY: verify-bucket
verify-bucket:
	kubectl wait --for=condition=Ready --timeout=30s storagebucket $(BUCKET)
	gsutil ls gs://$(BUCKET)
