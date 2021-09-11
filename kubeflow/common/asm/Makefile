# Get a list of stable versions of install_asm and config by running this command
# curl https://storage.googleapis.com/csm-artifacts/asm/STABLE_VERSIONS
# For example: 1.9.2-asm.1+config4:install_asm_1.9.2-asm.1-config4
# The part before colon symbol should be used for ASM_PACKAGE_VERSION.
# The part after colon symbol should be used for INSTALL_ASM_SCRIPT_VERSION.
ASM_PACKAGE_VERSION=1.10.4-asm.6+config2
INSTALL_ASM_SCRIPT_VERSION=install_asm_1.10.4-asm.6-config2
# ASM Upgrade Guide
# 1: Determine the ASM version you want to upgrade, follow the instruction above
#     to update ASM_PACKAGE_VERSION and INSTALL_ASM_SCRIPT_VERSION. Then run
#     `make install-asm` to install new ASM version.
# 2: Update kubeflow/env.sh for the ASM version, this looks like asm-192-1 format,
#     and you can find the exact value in istiod pod's label as well.
#     For example: You can find label `istio.io/rev: asm-192-1` in istiod-asm-192-1
#     service. Then run `source env.sh` under `kubeflow/` folder.
# 3: Run `bash kpt-set.sh` under `kubeflow/` folder. It will configure kpt setter
#     value for all components which requires to set ASM namespace label.
# 4: Follow official doc: https://cloud.google.com/service-mesh/docs/scripted-install/gke-upgrade#deploying_and_redeploying_workloads
#    to migrate workloads in each namespace, including user namespace created
#    in https://www.kubeflow.org/docs/components/multi-tenancy/getting-started/.
# 5: (Optional) Hydrate all Kubeflow resources to keep track of latest changes in build/.

# The name of the context for your Kubeflow cluster
NAME=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
LOCATION=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
PROJECT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')
UPSTREAM=upstream

.PHONY: download-install-asm-script
download-install-asm-script:
	curl https://storage.googleapis.com/csm-artifacts/asm/$(INSTALL_ASM_SCRIPT_VERSION) > install_asm;
# Official documentation of downloading install_asm: https://cloud.google.com/service-mesh/docs/scripted-install/asm-onboarding#downloading_the_script
# It cannot control the patch version so we won't use this approach for now.
# cd ./asm && { \
# 	curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9 > install_asm; \
# 	curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9.sha256 > install_asm.sha256; \
# 	sha256sum -c --ignore-missing install_asm.sha256; \
# 	chmod +x install_asm; \
# 	cd -;}

.PHONY: download-asm-package
download-asm-package:
	rm -rf ./asm
	kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm@$(ASM_PACKAGE_VERSION) ./

.PHONY: install-asm
install-asm: download-install-asm-script download-asm-package
	./install_asm \
	--project_id $(PROJECT) \
	--cluster_name $(NAME) \
	--cluster_location $(LOCATION) \
	--mode install \
	--enable_all \
	--custom_overlay ./asm/istio/options/iap-operator.yaml \
	--custom_overlay ./options/ingressgateway-iap.yaml


.PHONY: apply
apply: install-asm

.PHONY: hydrate
hydrate: # download-asmcli asmcli-validate asmcli-precheck
# There is no hydration for ASM, it is taken care by asmcli. But you can validate readiness using following commands.
# Require existence of a cluster before running MAKE commands:
# asmcli-validate asmcli-precheck

.PHONY: download-asmcli
download-asmcli: 
	curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_1.10.4-asm.6-config1-alpha > asmcli
	curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_1.10.4-asm.6-config1-alpha.sha256 > asmcli.sha256
	# curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_alpha > asmcli
	# curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_alpha.sha256 > asmcli.sha256
	chmod +x asmcli

.PHONY: asmcli-validate
asmcli-validate:
	./asmcli validate \
	--project_id $(PROJECT) \
	--cluster_name $(NAME) \
	--cluster_location $(LOCATION) \
	--output_dir $(UPSTREAM) \
	--ca mesh_ca \
	--custom_overlay ./$(UPSTREAM)/asm/istio/options/iap-operator.yaml \
	--custom_overlay ./options/ingressgateway-iap.yaml \
	--option legacy-default-ingressgateway \
	--verbose


.PHONY: asmcli-install
asmcli-install: download-asmcli
# --fleet_id is optional. If not specified, use project_id
	./asmcli install \
	--project_id $(PROJECT) \
	--cluster_name $(NAME) \
	--cluster_location $(LOCATION) \
	--output_dir $(UPSTREAM) \
	--enable_all \
	--ca mesh_ca \
	--custom_overlay ./$(UPSTREAM)/asm/istio/options/iap-operator.yaml \
	--custom_overlay ./options/ingressgateway-iap.yaml \
	--option legacy-default-ingressgateway \
	--verbose

.PHONY: asmcli-precheck
asmcli-precheck:
	pushd $(UPSTREAM) && ./istioctl experimental precheck && popd


# Note about install gateways
# https://cloud.google.com/service-mesh/docs/unified-install/install#install_gateways
# kubectl create namespace ingress-gateway
# kubectl -n istio-system get pods -l app=istiod --show-labels
# kubectl label namespace ingress-gateway istio-injection- istio.io/rev=asm-1104-6 --overwrite
# export INGRESS_GATEWAY=https://raw.githubusercontent.com/GoogleCloudPlatform/anthos-service-mesh-packages/release-1.10-asm/samples/gateways/istio-ingressgateway.yaml
# kubectl apply -n ingress-gateway -f ${INGRESS_GATEWAY}
