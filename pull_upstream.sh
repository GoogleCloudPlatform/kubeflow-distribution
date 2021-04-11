#!/usr/bin/env bash

set -ex

export KUBEFLOW_MANIFESTS_VERSION=v1.3.0-rc.0
# export KUBEFLOW_MANIFESTS_VERSION=v1.3.0
# export KUBEFLOW_MANIFESTS_VERSION=v1.2.0
export KUBEFLOW_MANIFESTS_REPO=https://github.com/kubeflow/manifests.git

# apps/ related manifest
if [ -d apps/admission-webhook/upstream ]; then
    rm -rf apps/admission-webhook/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/admission-webhook/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/admission-webhook


if [ -d apps/centraldashboard/upstream ]; then
    rm -rf apps/centraldashboard/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/centraldashboard/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/centraldashboard

if [ -d apps/jupyter/jupyter-web-app/upstream ]; then
    rm -rf apps/jupyter/jupyter-web-app/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/jupyter/jupyter-web-app/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/jupyter/jupyter-web-app

if [ -d apps/jupyter/notebook-controller/upstream ]; then
    rm -rf apps/jupyter/notebook-controller/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/jupyter/notebook-controller/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/jupyter/notebook-controller

if [ -d apps/profiles/upstream ]; then
    rm -rf apps/profiles/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/profiles/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/profiles

if [ -d apps/pytorch-job/upstream ]; then
    rm -rf apps/pytorch-job/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/pytorch-job/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/pytorch-job

if [ -d apps/tf-training/upstream ]; then
    rm -rf apps/tf-training/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/tf-training/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/tf-training

if [ -d apps/pipeline/upstream ]; then
    rm -rf apps/pipeline/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/pipeline/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/pipeline

if [ -d apps/kfserving/upstream ]; then
    rm -rf apps/kfserving/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/kfserving/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/kfserving

if [ -d apps/katib/upstream ]; then
    rm -rf apps/katib/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/katib/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/katib

if [ -d apps/volumes-web-app/upstream ]; then
    rm -rf apps/volumes-web-app/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/apps/volumes-web-app/upstream@$KUBEFLOW_MANIFESTS_VERSION apps/volumes-web-app

# common/ related manifest
if [ -d common/kubeflow-namespace/upstream ]; then
    rm -rf common/kubeflow-namespace/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/common/kubeflow-namespace/@$KUBEFLOW_MANIFESTS_VERSION common/kubeflow-namespace/upstream/

if [ -d common/istio/istio-1-9-0/ ]; then
    rm -rf common/istio/istio-1-9-0/
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/common/istio-1-9-0/@$KUBEFLOW_MANIFESTS_VERSION common/istio/istio-1-9-0

if [ -d common/cert-manager/upstream/ ]; then
    rm -rf common/cert-manager/upstream/
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/common/cert-manager/@$KUBEFLOW_MANIFESTS_VERSION common/cert-manager/upstream/

if [ -d common/kubeflow-roles/upstream/ ]; then
    rm -rf common/kubeflow-roles/upstream/
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/common/kubeflow-roles/@$KUBEFLOW_MANIFESTS_VERSION common/kubeflow-roles/upstream/

if [ -d common/knative/upstream ]; then
    rm -rf common/knative/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/common/knative/@$KUBEFLOW_MANIFESTS_VERSION common/knative/upstream/

if [ -d common/user-namespace/upstream ]; then
    rm -rf common/user-namespace/upstream
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/common/user-namespace/@$KUBEFLOW_MANIFESTS_VERSION common/user-namespace/upstream/

# contrib/ related manifest
if [ -d contrib/application/upstream/ ]; then
    rm -rf contrib/application/upstream/
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/contrib/application/@$KUBEFLOW_MANIFESTS_VERSION contrib/application/upstream/

if [ -d contrib/metacontroller/upstream/ ]; then
    rm -rf contrib/metacontroller/upstream/
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/contrib/metacontroller/@$KUBEFLOW_MANIFESTS_VERSION contrib/metacontroller/upstream/

if [ -d contrib/metacontroller/upstream/ ]; then
    rm -rf contrib/metacontroller/upstream/
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/contrib/metacontroller/@$KUBEFLOW_MANIFESTS_VERSION contrib/metacontroller/upstream/

if [ -d contrib/argo/upstream/ ]; then
    rm -rf contrib/argo/upstream/
fi
kpt pkg get $KUBEFLOW_MANIFESTS_REPO/contrib/argo/@$KUBEFLOW_MANIFESTS_VERSION contrib/argo/upstream/
