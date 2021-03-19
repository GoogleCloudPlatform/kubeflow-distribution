#***********************************************************************************************************************
# Edit this section to set the values specific to your deployment

.PHONY: set-cfg-values
set-cfg-values:
	kpt cfg set ./instance gke.private false

	kpt cfg set ./instance mgmt-ctxt <YOUR_MANAGEMENT_CTXT>

	kpt cfg set ./upstream/manifests/distributions/gcp name <YOUR_KF_NAME>
	kpt cfg set ./upstream/manifests/distributions/gcp gcloud.core.project <PROJECT_TO_DEPLOY_IN>
	kpt cfg set ./upstream/manifests/distributions/gcp gcloud.compute.zone <ZONE>
	kpt cfg set ./upstream/manifests/distributions/gcp location <REGION OR ZONE>
	kpt cfg set ./upstream/manifests/distributions/gcp log-firewalls false

	kpt cfg set ./upstream/manifests/distributions/stacks/gcp name <YOUR_KF_NAME>
	kpt cfg set ./upstream/manifests/distributions/stacks/gcp gcloud.core.project <PROJECT_TO_DEPLOY_IN>

	kpt cfg set ./instance name <YOUR_KF_NAME>
	kpt cfg set ./instance location <YOUR_REGION or ZONE>
	kpt cfg set ./instance gcloud.core.project <YOUR PROJECT>
	kpt cfg set ./instance email <YOUR_EMAIL_ADDRESS>
