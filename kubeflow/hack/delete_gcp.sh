#!/bin/bash
set -e

if [[ -z "${MGMTCTXT}" ]]; then
    echo "MGMTCTXT env var is required"
    exit 1
fi

echo "Deleting all Google Cloud resources including your GKE cluster and data in the cluster, except the Cloud SQL instance and GCS bucket. Confirm? [y/N]";
read REPLY;
if [[ "${REPLY}" =~ ^[Yy]$ ]]
then
    BUILD_DIR="${BUILD_DIR:-build}"
    kubectl --context="${MGMTCTXT}" delete -f "common/cnrm/${BUILD_DIR}"
fi
