# Get a list of stable versions of install_asm and config by running this command
# curl https://storage.googleapis.com/csm-artifacts/asm/STABLE_VERSIONS
# For example: 1.9.2-asm.1+config4:install_asm_1.9.2-asm.1-config4
# The part before colon symbol should be used for ASM_PACKAGE_VERSION.
# The part after colon symbol should be used for INSTALL_ASM_SCRIPT_VERSION.
ASM_PACKAGE_VERSION=1.10.4-asm.6+config2
INSTALL_ASM_SCRIPT_VERSION=install_asm_1.10.4-asm.6-config2
# ASM Upgrade Guide: Check out README.md of the same directory.

# The name of the context for your Kubeflow cluster
NAME=$(shell yq r ../kptconfig/kpt-setter-config.yaml 'data.name')
LOCATION=$(shell yq r ../kptconfig/kpt-setter-config.yaml 'data.location')
PROJECT=$(shell yq r ../kptconfig/kpt-setter-config.yaml 'data."gcloud.core.project"')
UPSTREAM=upstream

.PHONY: download-install-asm-script
download-install-asm-script:
	curl https://storage.googleapis.com/csm-artifacts/asm/$(INSTALL_ASM_SCRIPT_VERSION) > install_asm;
	chmod +x install_asm
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
	rm -rf asm.tar.gz
	curl -LJ https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages/archive/refs/tags/$(ASM_PACKAGE_VERSION).tar.gz -o asm.tar.gz 
	
	rm -rf ./package
	mkdir package
	tar -xf asm.tar.gz --strip-components=1 -C package 

.PHONY: install-asm
install-asm: download-install-asm-script download-asm-package
	./install_asm \
	--project_id $(PROJECT) \
	--cluster_name $(NAME) \
	--cluster_location $(LOCATION) \
	--mode install \
	--enable_all \
	--custom_overlay ./package/asm/istio/options/iap-operator.yaml \
	--custom_overlay ./options/ingressgateway-iap.yaml


.PHONY: apply
apply: install-asm

.PHONY: hydrate
hydrate: # download-asmcli asmcli-validate asmcli-precheck
# There is no hydration for ASM, it is taken care by install_asm/asmcli. 
# In the future, we will migrate to use asmcli, you can validate readiness using following commands.
# make asmcli-validate 
# make asmcli-precheck
# Note: Require existence of a cluster before running the commands above.

# Commands below are for asmcli, asmcli is in alpha state, we plan to migrate from install_asm to asmcli when ready.
.PHONY: download-asmcli
download-asmcli: 
	curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_alpha > asmcli
	curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_alpha.sha256 > asmcli.sha256
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
