# Set kpt setters using env vars.

set -ex

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
if [[ -z "${CLOUDSQL_NAME}" ]]; then
    echo "CLOUDSQL_NAME env var is required"
    exit 1
fi
if [[ -z "${BUCKET_NAME}" ]]; then
    echo "BUCKET_NAME env var is required"
    exit 1
fi

# kpt setter documentation:
# https://googlecontainertools.github.io/kpt/guides/consumer/set/
# kpt cfg set -R .  mgmt-ctxt "${MGMT_NAME}"

# kpt cfg set -R .  name "${KF_NAME}"
# kpt cfg set -R .  gcloud.core.project "${KF_PROJECT}"
# kpt cfg set -R .  gcloud.project.projectNumber "${KF_PROJECT_NUMBER}"
# kpt cfg set -R .  location "${LOCATION}"
# kpt cfg set -R .  gcloud.compute.zone "${ZONE}"
# kpt cfg set -R .  gcloud.compute.region "${REGION}"
# kpt cfg set -R .  email "${ADMIN_EMAIL}"

# kpt cfg set -R .  asm-label "${ASM_LABEL}"

# # common/managed-storage deploys specified CloudSQL and Cloud Storage bucket.
# kpt cfg set common/managed-storage cloudsql-name "${CLOUDSQL_NAME}"
# kpt cfg set common/managed-storage bucket-name "${BUCKET_NAME}"
# # apps/pipelines uses specified CloudSQL and Cloud Storage bucket.
# kpt cfg set apps/pipelines cloudsql-name "${CLOUDSQL_NAME}"
# kpt cfg set apps/pipelines bucket-name "${BUCKET_NAME}"
# kpt cfg set apps/pipelines default-pipeline-root "gs://${BUCKET_NAME}/v2/artifacts"

# kpt apply-setters reference: https://catalog.kpt.dev/apply-setters/v0.2/
# Apply environment variables to kpt config file.
kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.1 ./kptconfig -- \
    mgmt-ctxt="${MGMT_NAME}" \
    name="${KF_NAME}" \
    gcloud.core.project="${KF_PROJECT}" \
    gcloud.project.projectNumber="${KF_PROJECT_NUMBER}" \
    location="${LOCATION}" \
    gcloud.compute.zone="${ZONE}" \
    gcloud.compute.region="${REGION}" \
    email="${ADMIN_EMAIL}" \
    asm-label="${ASM_LABEL}" \
    cloudsql-name="${CLOUDSQL_NAME}" \
    bucket-name="${BUCKET_NAME}" \
    default-pipeline-root="gs://${BUCKET_NAME}/v2/artifacts" 


# Apply Kubeflow components using kpt config file.
kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.1 ./apps --fn-config ./kptconfig/kpt-setter-config.yaml --truncate-output=false
kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.1 ./common --fn-config ./kptconfig/kpt-setter-config.yaml --truncate-output=false
# Currently not needed for kpt-set in /contrib
# kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.1 ./contrib --fn-config ./kptconfig/kpt-setter-config.yaml --truncate-output=false

# Limitation on setting non-kRM yaml: https://github.com/GoogleContainerTools/kpt/issues/1218
# TODO: Use kpt fn instead of yq.
yq write -i apps/profiles/patches/namespace-labels.yaml '"istio.io/rev"' "${ASM_LABEL}"
