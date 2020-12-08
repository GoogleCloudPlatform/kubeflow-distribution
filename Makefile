# Reset various kpt values to default values and remove other
# files that shouldn't be included in PRs
# TODO(jlewi): We should add a test to make sure changed values don't get checked in
# We don't run it in generate because we don't want to force all developers to install kpt
clean-for-pr:
	rm -rf kubeflow/.build
	rm -rf management/.build

	rm -rf kubeflow/upstream/manifests
	rm -rf management/upstream/management

	kpt cfg set ./kubeflow/instance name KUBEFLOW-NAME
	kpt cfg set ./kubeflow/instance gcloud.core.project PROJECT
	kpt cfg set ./kubeflow/instance mgmt-ctxt MANAGEMENT-CTXT
	kpt cfg set ./kubeflow/instance email EMAIL
	kpt cfg set ./kubeflow/instance location LOCATION

	kpt cfg set ./management/instance name NAME
	kpt cfg set ./management/instance location LOCATION
	kpt cfg set ./management/instance gcloud.core.project PROJECT
	kpt cfg set ./management/instance managed-project MANAGED_PROJECT
