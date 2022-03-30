#!/bin/bash

set -ex

export SA_EMAIL="$(kubectl get ConfigConnectorContext -n config-control \
        -o jsonpath='{.items[0].spec.googleServiceAccount}' 2> /dev/null)" 
gcloud projects add-iam-policy-binding "${MGMT_PROJECT}" \
        --member "serviceAccount:${SA_EMAIL}" \
        --role "roles/owner" \
        --project "${MGMT_PROJECT}"