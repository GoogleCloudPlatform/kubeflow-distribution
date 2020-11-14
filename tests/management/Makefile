# Use .env file to include environment specific parameters
# Reference: https://lithic.tech/blog/2020-05/makefile-dot-env
ifneq (,$(wildcard ./.env))
    include .env
endif

# Test master
MANAGEMENT_URL?=https://github.com/kubeflow/gcp-blueprints.git/management@master

.PHONY: test
deploy-and-test: check-env 1-cluster 2-manage-project 3-bucket

.PHONY: cleanup
cleanup: check-env
	kubectl delete ns --wait $(MANAGED_PROJECT) || echo "already deleted"
	yes | gcloud projects remove-iam-policy-binding $(MANAGED_PROJECT) \
		--member=serviceAccount:$(NAME)-cnrm-system@$(PROJECT).iam.gserviceaccount.com \
		--role=roles/owner || echo "already deleted"
	yes | gcloud --project=$(PROJECT) iam service-accounts delete \
		$(NAME)-cnrm-system@$(PROJECT).iam.gserviceaccount.com || echo "already deleted"
	yes | gcloud --project=$(PROJECT) container clusters delete \
	   --zone=$(LOCATION) $(NAME) || echo "already deleted"

.PHONY: check-env
check-env:
ifeq (,$(wildcard ./.env))
	$(error ./.env configuration does not exist, please set up referring to ./example.env)
endif

.PHONY: 1-cluster
1-cluster: check-env get-pkg set-values apply-cluster

.PHONY: 2-manage-project
2-manage-project: check-env create-ctxt apply-kcc apply-managed-project

.PHONY: bucket
3-bucket: check-env apply-bucket verify-bucket

.PHONY: get-pkg
get-pkg:
	rm -rf management
	kpt pkg get $(MANAGEMENT_URL) .
	cd management && make get-pkg

.PHONY: set-values
set-values: check-env
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
	kubectl apply -f ./storagebucket.yaml

.PHONY: verify-bucket
verify-bucket:
	kubectl wait --for=condition=Ready --timeout=30s storagebucket $(BUCKET)
	gsutil ls gs://$(BUCKET)
