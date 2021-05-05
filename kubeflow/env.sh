export KF_NAME=<kubeflow-cluster-name>
export KF_PROJECT=<gcp-project-id>
export KF_PROJECT_NUMBER=$(gcloud projects describe "${KF_PROJECT}" --format='value(projectNumber)')
export KF_DIR=<kubeflow-download-path>
export MGMT_NAME=<management-cluster-name>
export MGMTCTXT="${MGMT_NAME}"
export LOCATION=<zone>
export ADMIN_EMAIL=<administrator-full-email-address>

source ./common/asm/env.sh
