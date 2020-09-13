#!/bin/bash
#
# A simple helper script to create a kubeconfig context for a particular cluster.
#
# usage
# PROJECT=<PROJECT> REGION=<region> NAME=<NAME>
#
# TODO(jlewi): Support zonal clusters as well
# TODO(jlewi): How should we dedupe with kubeflow/hack?
# Should we make hack its own package and put it in upstream?
set -x

# Delete kubeconfig context if exist already
kubectl config delete-context ${NAME} || echo "Ignore error - context ${NAME} does not exist"

set -ex

# Get the context
gcloud --project=${PROJECT} container clusters get-credentials \
	   --region=${REGION} ${NAME}

# Rename the context
kubectl config rename-context $(kubectl config current-context) ${NAME}

# Set the namespace to the host project
kubectl config set-context --current --namespace=cnrm-system