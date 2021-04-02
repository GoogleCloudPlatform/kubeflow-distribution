#!/usr/bin/env bash

set -ex

export KUBEFLOW_MANIFESTS_VERSION=v1.3.0-rc.0
# export KUBEFLOW_MANIFESTS_VERSION=v1.3.0
# export KUBEFLOW_MANIFESTS_VERSION=v1.2.0
export KUBEFLOW_MANIFESTS_REPO=https://github.com/kubeflow/manifests.git


if [ -d apps/admission-webhook/upstream ]; then
    rm -rf apps/admission-webhook/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/admission-webhook/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/admission-webhook


if [ -d apps/centraldashboard/upstream ]; then
    rm -rf apps/centraldashboard/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/centraldashboard/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/centraldashboard


if [ -d common/kubeflow-namespace/base ]; then
    rm -rf common/kubeflow-namespace/base
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/common/kubeflow-namespace/base@$KUBEFLOW_MANIFESTS_VERSION common/kubeflow-namespace

sudo chmod -R 777 ./