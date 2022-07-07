# ASM was upgraded to v1.13 in Kubeflow for GCP v1.5.1
# ASM changed the installation process begining v1.12. See details:
# https://cloud.google.com/service-mesh/docs/unified-install/anthos-service-mesh-prerequisites
# To upgrade your current ASM instance, please follow instructions:
# https://cloud.google.com/service-mesh/docs/unified-install/plan-upgrade
#
# Get a list of stable versions of asmcli and config by running this command
# curl https://storage.googleapis.com/csm-artifacts/asm/ASMCLI_VERSIONS
# For example: 1.13.2-asm.5+config2:asmcli_1.13.2-asm.5-config2
# The part before colon symbol should be used for ASM_PACKAGE_VERSION.
# The part after colon symbol should be used for ASMCLI_SCRIPT_VERSION.

ASM_PACKAGE_VERSION=1.13.2-asm.5+config2
ASMCLI_SCRIPT_VERSION=asmcli_1.13.2-asm.5-config2

# The name of the context for your Kubeflow cluster
PACKAGE_DIR?=$(shell pwd)/..

YQ=docker run --rm -v "$(PACKAGE_DIR)/":/workdir mikefarah/yq:4
NAME=$(shell $(YQ) e '.data.name' kptconfig/kpt-setter-config.yaml)
PROJECT=$(shell $(YQ) e '.data."gcloud.core.project"' kptconfig/kpt-setter-config.yaml)
LOCATION=$(shell $(YQ) e '.data.location' kptconfig/kpt-setter-config.yaml)

UPSTREAM=upstream

.PHONY: download-asmcli
download-asmcli: 
	curl https://storage.googleapis.com/csm-artifacts/asm/$(ASMCLI_SCRIPT_VERSION) > asmcli;
	chmod +x asmcli

.PHONY: download-asm-package
download-asm-package:
	rm -rf asm.tar.gz
	curl -LJ https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages/archive/refs/tags/$(ASM_PACKAGE_VERSION).tar.gz -o asm.tar.gz 
	
	rm -rf ./package
	mkdir package
	tar -xf asm.tar.gz --strip-components=1 -C package 

.PHONY: install-asm
install-asm: download-asmcli download-asm-package
	./asmcli install \
	--project_id $(PROJECT) \
	--cluster_name $(NAME) \
	--cluster_location $(LOCATION) \
	--output_dir $(UPSTREAM) \
	--enable_all \
	--ca mesh_ca \
	--custom_overlay ./package/asm/istio/options/iap-operator.yaml \
	--custom_overlay ./options/ingressgateway-iap.yaml \
	--option legacy-default-ingressgateway \
	--verbose

.PHONY: apply
apply: install-asm

.PHONY: hydrate
hydrate: download-asmcli download-asm-package asmcli-validate asmcli-precheck

.PHONY: asmcli-validate
asmcli-validate:
	./asmcli validate \
	--project_id $(PROJECT) \
	--cluster_name $(NAME) \
	--cluster_location $(LOCATION) \
	--output_dir $(UPSTREAM) \
	--ca mesh_ca \
	--custom_overlay ./package/asm/istio/options/iap-operator.yaml \
	--custom_overlay ./options/ingressgateway-iap.yaml \
	--option legacy-default-ingressgateway \
	--verbose

.PHONY: asmcli-precheck
asmcli-precheck:
	pushd ${UPSTREAM} && ./istioctl experimental precheck && popd
# Note about install gateways
# https://cloud.google.com/service-mesh/docs/unified-install/install#install_gateways

