# Get a list of stable versions of install_asm and config by running this command
# curl https://storage.googleapis.com/csm-artifacts/asm/STABLE_VERSIONS
# For example: 1.9.2-asm.1+config4:install_asm_1.9.2-asm.1-config4
# The part before colon symbol should be used for ASM_PACKAGE_VERSION.
# The part after colon symbol should be used for INSTALL_ASM_SCRIPT_VERSION.
# You might need to change corresponding kpt value in kubeflow/kpt-set.sh if you upgrade 
ASM_PACKAGE_VERSION=1.9.2-asm.1+config4
INSTALL_ASM_SCRIPT_VERSION=install_asm_1.9.2-asm.1-config4


# The name of the context for your Kubeflow cluster
# NAME=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
# LOCATION=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
# PROJECT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')

.PHONY: downalod-install-asm-script
downalod-install-asm-script:
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
install-asm: downalod-install-asm-script download-asm-package
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
hydrate: 
# There is no hydration for ASM, it is taken care by install_asm.
