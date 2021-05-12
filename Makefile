#***********************************************************************************************************************
# Edit this section to set the values specific to your deployment

.PHONY: set-cfg-values
set-cfg-values:
	kpt cfg set -R .  gke.private false

	kpt cfg set -R .  mgmt-ctxt <YOUR_MANAGEMENT_CTXT>

	kpt cfg set -R .  name <YOUR_KF_NAME>
	kpt cfg set -R .  gcloud.project.projectNumber <PROJECT_NUMBER_TO_DEPLOY_IN>
	kpt cfg set -R .  gcloud.core.project <PROJECT_ID_TO_DEPLOY_IN>
	kpt cfg set -R .  gcloud.compute.zone <ZONE>
	kpt cfg set -R .  location <REGION OR ZONE>
	kpt cfg set -R .  log-firewalls false

	kpt cfg set -R .  email <YOUR_EMAIL_ADDRESS>

# Reset various kpt values to default values and remove other
# files that shouldn't be included in PRs
# TODO(jlewi): We should add a test to make sure changed values don't get checked in
# We don't run it in generate because we don't want to force all developers to install kpt
clean-for-pr: reset-cfg-values
	rm -rf kubeflow/.build
	rm -rf management/.build

	rm -rf kubeflow/upstream/manifests
	rm -rf management/upstream/management

.PHONY: reset-cfg-values
reset-cfg-values:
	kpt cfg set -R . gke.private false

	kpt cfg set -R . mgmt-ctxt MANAGEMENT-CTXT

	kpt cfg set -R . name KUBEFLOW-NAME
	kpt cfg set -R . gcloud.core.project PROJECT
	kpt cfg set -R . gcloud.project.projectNumber PROJECT_NUMBER
	kpt cfg set -R . location LOCATION
	kpt cfg set -R . gcloud.compute.zone ZONE
	kpt cfg set -R . gcloud.compute.region REGION
	kpt cfg set -R . log-firewalls false
	kpt cfg set -R . bucket-name BUCKET-NAME
	kpt cfg set -R . cloudsql-name CLOUDSQL-NAME

	kpt cfg set -R . email EMAIL
