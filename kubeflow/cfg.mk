#***********************************************************************************************************************
# Edit this section to set the values specific to your deployment

.PHONY: set-cfg-values
set-cfg-values:
	kpt cfg set ./instance gke.private false

	kpt cfg set ./instance mgmt-ctxt <YOUR_MANAGEMENT_CTXT>

	kpt cfg set ../packages/gcp-resources name <YOUR_KF_NAME>
	kpt cfg set ../packages/gcp-resources  gcloud.core.project <PROJECT_TO_DEPLOY_IN>
	kpt cfg set ../packages/gcp-resources  gcloud.compute.zone <ZONE>
	kpt cfg set ../packages/gcp-resources  location <REGION OR ZONE>
	kpt cfg set ../packages/gcp-resources  log-firewalls false
	
	kpt cfg set ./instance name <YOUR_KF_NAME>
	kpt cfg set ./instance location <YOUR_REGION or ZONE>
	kpt cfg set ./instance gcloud.core.project <YOUR PROJECT>
	kpt cfg set ./instance email <YOUR_EMAIL_ADDRESS>

	kpt cfg set ./instance/kustomize/kubeflow-apps/apps name <YOUR_KF_NAME>
	kpt cfg set ./instance/kustomize/kubeflow-apps/apps gcloud.core.project <YOUR PROJECT>
