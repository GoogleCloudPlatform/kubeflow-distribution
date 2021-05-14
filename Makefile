.PHONY: reset-cfg-values
reset-cfg-values:
	kpt cfg set -R kubeflow name KUBEFLOW-NAME

	kpt cfg set -R management name MANAGEMENT-NAME
	kpt cfg set -R . mgmt-ctxt MANAGEMENT-CTXT

	kpt cfg set -R . gcloud.core.project PROJECT
	kpt cfg set -R . location LOCATION
	kpt cfg set -R . gcloud.compute.zone ZONE
	kpt cfg set -R . gcloud.compute.region REGION
	kpt cfg set -R . bucket-name BUCKET-NAME
	kpt cfg set -R . cloudsql-name CLOUDSQL-NAME

	kpt cfg set -R . email EMAIL

	kpt cfg set -R . gke.private false
	kpt cfg set -R . log-firewalls false
