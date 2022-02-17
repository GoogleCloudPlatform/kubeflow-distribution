# Deprecated for kpt pre-1.0.0 syntax.
# kpt cfg set -R . name "${MGMT_NAME}"
# kpt cfg set -R . gcloud.core.project "${MGMT_PROJECT}"
# kpt cfg set -R . location "${LOCATION}"

# kpt 1.0.0+ syntax
kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.1 ./kptconfig -- \
    name="${MGMT_NAME}" \
    gcloud.core.project="${MGMT_PROJECT}" \
    location="${LOCATION}" \

kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.1 ./manifests --fn-config ./kptconfig/kpt-setter-config.yaml --truncate-output=false
