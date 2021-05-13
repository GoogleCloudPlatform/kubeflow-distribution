# 1. Edit <placeholders>.
# 2. Other env vars are configurable, but with default values set below.

# Your Google Cloud project ID
export KF_PROJECT=<gcp-project-id>
# You can get your project number by running this command:
# gcloud projects describe --format='value(projectNumber)' "${KF_PROJECT}"
export KF_PROJECT_NUMBER=<gcp-project-number>
# Kubeflow Admin email address
# Example: admin@gmail.com
export ADMIN_EMAIL=<administrator-full-email-address>
# The management cluster name you have already deployed following:
# https://www.kubeflow.org/docs/distributions/gke/deploy/management-setup/
export MGMT_NAME=<management-cluster-name>
# Management cluster kubectl context name, defaults to ${MGMT_NAME} if you
# followed the above guide.
export MGMTCTXT="${MGMT_NAME}"

######################
# NOTICE: The following env vars have a default value, but they are also configurable.
######################

# KF_NAME is your Kubeflow cluster name.
# It should satisfy the following conditions:
# * is unique within your project.
# * alphanumeric characters and hyphen "-" only.
# * starts with a letter.
# * ends with an alphanumeric character.
export KF_NAME=kubeflow
# LOCATION can either be a zone or a region, that determines whether
# Kubeflow cluster is a zonal cluster or a regional cluster.
export LOCATION=us-central1-c
# Specify a region like the following line to create a regional Kubeflow cluster.
# export LOCATION=us-central1

# REGION should match LOCATION.
export REGION=us-central1
# Preferred zone of Cloud SQL. Note, ZONE should be in REGION.
export ZONE=us-central1-c
# Anthos Service Mesh version label
export ASM_LABEL=asm-192-1
