# Set kpt setters using env vars.

set -ex

<<<<<<< HEAD
if [[ -z "${KF_NAME}" ]]; then
    echo "KF_NAME env var is required"
    exit 1
fi
if [[ -z "${MGMT_NAME}" ]]; then
    echo "MGMT_NAME env var is required"
    exit 1
fi
if [[ -z "${KF_PROJECT}" ]]; then
    echo "KF_PROJECT env var is required"
    exit 1
fi
if [[ -z "${KF_PROJECT_NUMBER}" ]]; then
    echo "KF_PROJECT_NUMBER env var is required"
    exit 1
fi
if [[ -z "${LOCATION}" ]]; then
    echo "LOCATION env var is required"
    exit 1
fi
if [[ -z "${ZONE}" ]]; then
    echo "ZONE env var is required"
    exit 1
fi
if [[ -z "${REGION}" ]]; then
    echo "REGION env var is required"
    exit 1
fi
if [[ -z "${ADMIN_EMAIL}" ]]; then
    echo "ADMIN_EMAIL env var is required"
    exit 1
fi
if [[ -z "${ASM_LABEL}" ]]; then
    echo "ASM_LABEL env var is required"
    exit 1
fi

# kpt setter documentation:
# https://googlecontainertools.github.io/kpt/guides/consumer/set/
=======
kpt cfg set -R .  gke.private false

>>>>>>> upstream/master
kpt cfg set -R .  mgmt-ctxt "${MGMT_NAME}"

kpt cfg set -R .  name "${KF_NAME}"
kpt cfg set -R .  gcloud.core.project "${KF_PROJECT}"
<<<<<<< HEAD
kpt cfg set -R .  gcloud.project.projectNumber "${KF_PROJECT_NUMBER}"
kpt cfg set -R .  location "${LOCATION}"
kpt cfg set -R .  gcloud.compute.zone "${ZONE}"
kpt cfg set -R .  gcloud.compute.region "${REGION}"
kpt cfg set -R .  email "${ADMIN_EMAIL}"

kpt cfg set -R .  asm-label "${ASM_LABEL}"

# Default values for managed storage used by Kubeflow Pipelines (KFP), you can
# override as you like.
# The CloudSQL instance and Cloud Storage bucket instance are created during
# deployment, so you should make sure their names are not used before.
CLOUDSQL_NAME="${KF_NAME}-kfp"
BUCKET_NAME="${KF_PROJECT}-kfp"
# common/managed-storage deploys specified CloudSQL and Cloud Storage bucket.
kpt cfg set common/managed-storage cloudsql-name "${CLOUDSQL_NAME}"
kpt cfg set common/managed-storage bucket-name "${BUCKET_NAME}"
# apps/pipelines uses specified CloudSQL and Cloud Storage bucket.
kpt cfg set apps/pipelines cloudsql-name "${CLOUDSQL_NAME}"
kpt cfg set apps/pipelines bucket-name "${BUCKET_NAME}"
=======
kpt cfg set -R .  gcloud.compute.zone "${LOCATION}"
kpt cfg set -R .  location "${LOCATION}"
kpt cfg set -R .  log-firewalls false

kpt cfg set -R .  email "${ADMIN_EMAIL}"

kpt cfg set -R .  asm-label "${ASM_LABEL}"

# Default values for Kubeflow Pipelines, you can override as you like.
kpt cfg set apps/pipelines cloudsql-name "${KF_NAME}-kfp"
kpt cfg set apps/pipelines bucket-name "${KF_NAME}-kfp-artifacts"

kpt cfg set -R .  gcloud.project.projectNumber "${KF_PROJECT_NUMBER}"
>>>>>>> upstream/master
