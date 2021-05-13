#!/bin/bash
set -ex

if [[ -z "${MGMTCTXT}" ]]; then
    echo "MGMTCTXT env var is required"
    exit 1
fi

echo "Deleting all GCP resources will cause destruction of all services and data on this cluster. Confirm? [y/N]";
read REPLY;
if [[ "${REPLY}" =~ ^[Yy]$ ]]
then
    BUILD_DIR="${BUILD_DIR:-build}"
    kubectl --context="${MGMTCTXT}" delete -f "common/cnrm/${BUILD_DIR}"
fi
