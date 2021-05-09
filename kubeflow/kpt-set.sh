
# Use kpt to set kustomize values

bash common/asm/kpt-set.sh

kpt cfg set -R .  gke.private false

kpt cfg set -R .  mgmt-ctxt "${MGMT_NAME}"

kpt cfg set -R .  name "${KF_NAME}"
kpt cfg set -R .  gcloud.project.projectNumber "${KF_PROJECT_NUMBER}"
kpt cfg set -R .  gcloud.core.project "${KF_PROJECT}"
kpt cfg set -R .  gcloud.compute.zone "${LOCATION}"
kpt cfg set -R .  location "${LOCATION}"
kpt cfg set -R .  log-firewalls false

kpt cfg set -R .  email "${ADMIN_EMAIL}"

# Default values for Kubeflow Pipelines, you can override as you like.
kpt cfg set kubeflow/apps/pipeline cloudsql-name "${KF_NAME}-kfp"
kpt cfg set kubeflow/apps/pipeline bucket-name "${KF_NAME}-kfp-artifacts"
