# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

NAME=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
KF_PROJECT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')
# The context for your management cluster
MGMTCTXT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.mgmt-ctxt".x-k8s-cli.setter.value')
# The context for your Kubeflow cluster
KFCTXT=$(NAME)
build_dir?=./build

.PHONY: hydrate
hydrate:
	rm -rf $(build_dir)
	mkdir -p $(build_dir)/k8s
	mkdir -p $(build_dir)/cnrm
	# Hydrate GCP config connector resources
	kustomize build -o $(build_dir)/cnrm ./cnrm
	# Hydrate Kubernetes resources
	kustomize build -o $(build_dir)/k8s .

.PHONY: apply
apply: apply-cnrm wait-cnrm apply-k8s

.PHONY: apply-cnrm
apply-cnrm: hydrate
	kubectl --context=$(MGMTCTXT) apply -f $(build_dir)/cnrm

.PHONY: apply-k8s
apply-k8s: hydrate
	kubectl --context=$(KFCTXT) apply -f $(build_dir)/k8s

.PHONY: wait-cnrm
wait-cnrm:
	# Wait for all Google Cloud resources to get created and become ready.
	# If this takes long, you can view status by:
	@echo "kubectl --context=$(MGMTCTXT) -n $(KF_PROJECT) get -f $(build_dir)/cnrm"
	# For resources with READY=False, debug by:
	@echo "kubectl --context=$(MGMTCTXT) -n $(KF_PROJECT) describe <KIND>/<NAME>"
	@echo
	kubectl --context=$(MGMTCTXT) wait --for=condition=Ready --timeout=600s -f $(build_dir)/cnrm
