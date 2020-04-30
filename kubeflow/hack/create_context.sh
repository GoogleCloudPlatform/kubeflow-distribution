#!/bin/bash
#
# A simple helper script to create a kubeconfig context for a particular cluster.
#
# usage
# PROJECT=<PROJECT> REGION=<region> NAME=<NAME>
#
# TODO(jlewi): Support zonal clusters as well
set -x 

echo Checking if context ${NAME} exists 

kubectl config use-context ${NAME}

RESULT=$?

if [ ${RESULT} -eq 0 ]; then
echo kubeconfig context ${NAME} already exists
exit 0
fi

set -ex

# TODO test if the context already exists and if it does do nothing
gcloud --project=${PROJECT} container clusters get-credentials \
	   --region=${REGION} ${NAME}

# Rename the context
kubectl config rename-context $(kubectl config current-context) ${NAME}

# Set the namespace to the host project
kubectl config set-context --current --namespace=kubeflow