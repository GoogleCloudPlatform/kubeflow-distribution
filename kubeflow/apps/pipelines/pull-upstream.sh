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

set -ex

# TODO(Bobgy): use KFP 1.6.1 when https://github.com/kubeflow/pipelines/pull/5750 is released.
# export KUBEFLOW_PIPELINES_VERSION=1.7.0
# export KUBEFLOW_PIPELINES_REPO=https://github.com/kubeflow/pipelines.git
export KUBEFLOW_PIPELINES_VERSION=upgradekpt # krmignore # kubeflow14
export KUBEFLOW_PIPELINES_REPO=https://github.com/zijianjoy/pipelines.git
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
