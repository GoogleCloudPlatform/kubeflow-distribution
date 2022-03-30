#!/bin/bash
set -e

# Reference: https://cloud.google.com/anthos-config-management/docs/how-to/config-controller-setup#delete_your	
echo -e ""
echo "Make sure you have delete all resources managed by management cluster."
echo "Resource not explicitly deleted will stay orphan if you delete the management cluster directly."


if [[ -z "${MGMT_PROJECT}" ]]; then
    echo "MGMT_PROJECT env var is required"
    exit 1
fi

if [[ -z "${MGMTCTXT}" ]]; then
    echo "MGMTCTXT env var is required"
    exit 1
fi

if [[ -z "${LOCATION}" ]]; then
    echo "LOCATION env var is required"
    exit 1
fi

read -p "Deleting management cluster. Confirm? [y/N] " REPLY;
if [[ "${REPLY}" =~ ^[Yy]$ ]]
then
    gcloud config set project ${MGMT_PROJECT}
    gcloud anthos config controller delete --location=${LOCATION} ${MGMTCTXT}
fi
