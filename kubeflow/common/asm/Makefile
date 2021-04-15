
# The name of the context for your Kubeflow cluster
NAME=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.name".x-k8s-cli.setter.value')
LOCATION=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.location".x-k8s-cli.setter.value')
PROJECT=$(shell yq r ./Kptfile 'openAPI.definitions."io.k8s.cli.setters.gcloud.core.project".x-k8s-cli.setter.value')

.PHONY: install-asm-script
install-asm-script:
	mkdir -p ./asm;
	cd ./asm && { \
		curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9 > install_asm; \
		curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_1.9.sha256 > install_asm.sha256; \
		sha256sum -c --ignore-missing install_asm.sha256; \
		chmod +x install_asm; \
		cd -;}

.PHONY: install-asm
install-asm: install-asm-script
	rm -rf ./asm
	kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm@1.9.1-asm.1+config3 ./
	./install_asm \
	--project_id $(PROJECT) \
	--cluster_name $(NAME) \
	--cluster_location $(LOCATION) \
	--mode install \
	--enable_all \
	--custom_overlay ./asm/istio/options/iap-operator.yaml