# kpt 1.0.0+ syntax
FILEPATH=$(dirname "$0")
kpt fn eval --image gcr.io/kpt-fn/apply-setters:v0.1 ${FILEPATH}/kcc-namespace -- \
    project-id="${KF_PROJECT}" \
    management-project-id="${MGMT_PROJECT}" \
    management-namespace="config-control" \
    networking-namespace="config-control" \
    projects-namespace="config-control" 
