#!/bin/bash

# Call certain component's make apply if Makefile exists,
# or use kustomize and kubectl to apply the kustomization.yaml resources.
# 
# Run this script under kubeflow/ path. (One level above current hack/ directory)
# Run this as PROJECT=$(PROJECT) NAME=$(NAME) KFCTXT=$(KFCTXT) LOCATION=$(LOCATION) ./apply_component -path <component path under kubeflow>
# For example: PROJECT=gcp-project NAME=cluster-name KFCTXT=cluster-context LOCATION=us-west1-b ./apply_component -path common/kubeflow-namespace
# To set build directory other than ./build, use the following command:
# BUILD_DIR=$(GENERATED_RESOURCE_LOCATION) PROJECT=$(PROJECT) NAME=$(NAME) KFCTXT=$(KFCTXT) LOCATION=$(LOCATION) ./apply_component -path <component path under kubeflow>

if [ $# -ne 2 ]; then
   echo "Please provide component path: -path <component path under kubeflow>"
   echo "For example: '-path common/cnrm' will apply resources under kubeflow/common/cnrm."
   exit 1
fi

if [ "$1" != "-path" ]; then
  echo "Please provide -path flag. Usage is -path <component path under kubeflow>."
fi

[ ! -n "$BUILD_DIR" ] && BUILD_DIR=./build
echo "Build directory: $BUILD_DIR"

component_path=$2
echo "Component path: $component_path"
makefile_path=./$component_path/Makefile
echo "Apply component resources: $component_path"
if [ -f $makefile_path ] ; then 
    echo "Found Makefile, call 'make apply' of this component Makefile. "
    NAME=$NAME KFCTXT=$KFCTXT LOCATION=$LOCATION PROJECT=$PROJECT make -C $component_path apply build_dir=$BUILD_DIR
else
    echo 'Makefile not found, use kustomize and kubectl to apply resources.'
    component_build_dir=./$component_path/$BUILD_DIR
    rm -rf $component_build_dir && mkdir -p $component_build_dir
    kustomize build -o $component_build_dir ./$component_path
    kubectl --context=$KFCTXT apply -f $component_build_dir
fi
