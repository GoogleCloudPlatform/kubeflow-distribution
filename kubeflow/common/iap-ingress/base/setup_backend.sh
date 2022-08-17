#!/usr/bin/env bash
#
# A simple shell script to configure the JWT audience used with ISTIO

set -x
[ -z ${NAMESPACE} ] && echo Error NAMESPACE must be set && exit 1
[ -z ${SERVICE} ] && echo Error SERVICE must be set && exit 1
[ -z ${INGRESS_NAME} ] && echo Error INGRESS_NAME must be set && exit 1

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/project-id)
if [ -z ${PROJECT} ]; then
    echo Error unable to fetch PROJECT from compute metadata
    exit 1
fi

PROJECT_NUM=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/numeric-project-id)
if [ -z ${PROJECT_NUM} ]; then
    echo Error unable to fetch PROJECT_NUM from compute metadata
    exit 1
fi

# Activate the service account
if [ ! -z "${GOOGLE_APPLICATION_CREDENTIALS}" ]; then
    # As of 0.7.0 we should be using workload identity and never setting GOOGLE_APPLICATION_CREDENTIALS.
    # But we kept this for backwards compatibility but can remove later.
    gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
fi

# Print out the config for debugging
gcloud config list
gcloud auth list

set_jwt_policy () {
    NODE_PORT=$(kubectl --namespace=${NAMESPACE} get svc ${SERVICE} -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
    echo "node port is ${NODE_PORT}"

    BACKEND_NAME=""
    while [[ -z ${BACKEND_NAME} ]]; do
    BACKENDS=$(kubectl --namespace=${NAMESPACE} get ingress ${INGRESS_NAME} -o jsonpath='{.metadata.annotations.ingress\.kubernetes\.io/backends}')
    echo "fetching backends info with ${INGRESS_NAME}: ${BACKENDS}"
    BACKEND_NAME=$(echo $BACKENDS | grep -o "k8s-be-${NODE_PORT}--[0-9a-z]\+")
    echo "backend name is ${BACKEND_NAME}"
    sleep 2
    done

    BACKEND_ID=""
    while [[ -z ${BACKEND_ID} ]]; do
    BACKEND_ID=$(gcloud compute --project=${PROJECT} backend-services list --filter=name~${BACKEND_NAME} --format='value(id)')
    echo "Waiting for backend id PROJECT=${PROJECT} NAMESPACE=${NAMESPACE} SERVICE=${SERVICE} filter=name~${BACKEND_NAME}"
    sleep 2
    done
    echo BACKEND_ID=${BACKEND_ID}

    JWT_AUDIENCE="/projects/${PROJECT_NUM}/global/backendServices/${BACKEND_ID}"
    echo "Upsert RequestAuthentication with JWT audience: ${JWT_AUDIENCE}"
    sed "s|JWT_AUDIENCE|${JWT_AUDIENCE}|" ${__dir}/policy.yaml | kubectl apply -n ${NAMESPACE} -f -

    echo "Clearing lock on service annotation"
    kubectl patch svc "${SERVICE}" -n istio-system -p "{\"metadata\": { \"annotations\": {\"backendlock\": \"\" }}}"
}

while true; do
    set_jwt_policy
    # Every 5 minutes recheck the JWT policy and reset it if the backend has changed for some reason.
    # This follows Kubernetes level based design.
    # We have at least one report see 
    # https://github.com/kubeflow/kubeflow/issues/4342#issuecomment-544653657
    # of the backend id changing over time.
    sleep 300
done
