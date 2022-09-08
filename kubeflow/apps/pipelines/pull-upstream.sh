#!/usr/bin/env bash
#
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Pulls manifests for Kubeflow Pipelines into the ./upstream folder
# Arguments:
#   $1 must be a Git repository. E.g. https://github.com/kubeflow/pipelines.git
#   $2 must be a TAG or Commit SHA sum. E.g. 2.0.0-alpha.4
# Output:
#   Print messages for debugging
set -ex

if [ $# -eq 2 ]
  then
    echo "Provide input values for KUBEFLOW_PIPELINES_REPO and KUBEFLOW_PIPELINES_VERSION.
    E.g. ./apps/pipelines/pull_upstream.sh https://github.com/kubeflow/pipelines.git 2.0.0-alpha.4"
    exit 1
fi

# TODO: Use kubeflow/pipelines once https://github.com/kubeflow/pipelines/pull/6595 is resolved.
KUBEFLOW_PIPELINES_VERSION=$2
KUBEFLOW_PIPELINES_REPO=$1
# export KUBEFLOW_PIPELINES_VERSION=upgradekpt # Other attempted branches: krmignore, kubeflow14
# export KUBEFLOW_PIPELINES_REPO=https://github.com/zijianjoy/pipelines.git
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"

cd "${DIR}"
if [ -d upstream ]; then
    rm -rf upstream
fi
# mkdir -p upstream
kpt pkg get "${KUBEFLOW_PIPELINES_REPO}/manifests/kustomize/@${KUBEFLOW_PIPELINES_VERSION}" upstream
rm upstream/Kptfile
# kpt pkg get "${KUBEFLOW_PIPELINES_REPO}/manifests/kustomize/@${KUBEFLOW_PIPELINES_VERSION}" upstream
# mv upstream/kustomize/* upstream
