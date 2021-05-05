#!/bin/bash
set -e

# Call certain component's make apply if Makefile exists,
# or use kustomize and kubectl to apply the kustomization.yaml resources.
# 
# Run this script under kubeflow/ path. (One level above current hack/ directory)
# Run this as PROJECT=$(PROJECT) NAME=$(NAME) KFCTXT=$(KFCTXT) LOCATION=$(LOCATION) ./apply_component -path <component path under kubeflow>
# For example: PROJECT=gcp-project NAME=cluster-name KFCTXT=cluster-context LOCATION=us-west1-b ./apply_component -path common/kubeflow-namespace
# To set build directory other than ./build, use the following command:
# BUILD_DIR=$(GENERATED_RESOURCE_LOCATION) PROJECT=$(PROJECT) NAME=$(NAME) KFCTXT=$(KFCTXT) LOCATION=$(LOCATION) ./apply_component -path <component path under kubeflow>

HYDRATE_ONLY="${HYDRATE_ONLY:=0}"
COMPONENT_PATH=""

main() {
  parse_args "${@}"

  [ ! -n "$BUILD_DIR" ] && BUILD_DIR=./build
  echo "Build directory: $BUILD_DIR"

  COMPONENT_PATH=$2
  echo "Component path: $COMPONENT_PATH"
  makefile_path=./$COMPONENT_PATH/Makefile
  echo "Apply component resources: $COMPONENT_PATH"
  if [ -f $makefile_path ] ; then 
      echo "Found Makefile, call 'make apply' of this component Makefile. "
      if [ $HYDRATE_ONLY -ne 1 ]; then
        NAME=$NAME KFCTXT=$KFCTXT LOCATION=$LOCATION PROJECT=$PROJECT make -C $COMPONENT_PATH apply build_dir=$BUILD_DIR
      else
        NAME=$NAME KFCTXT=$KFCTXT LOCATION=$LOCATION PROJECT=$PROJECT make -C $COMPONENT_PATH hydrate build_dir=$BUILD_DIR
      fi
  else
      echo 'Makefile not found, use kustomize and kubectl to apply resources.'
      component_build_dir=./$COMPONENT_PATH/$BUILD_DIR
      rm -rf $component_build_dir && mkdir -p $component_build_dir
      kustomize build -o $component_build_dir ./$COMPONENT_PATH
      if [ $HYDRATE_ONLY -ne 1 ]; then
        kubectl --context=$KFCTXT apply -f $component_build_dir
      fi
  fi
}


parse_args() {
  if [[ "${*}" = '' ]]; then
    echo "Please provide component path: -path <component path under kubeflow>"
    echo "For example: '-path common/cnrm' will apply resources under kubeflow/common/cnrm."
    exit 1
  fi

  while [[ $# != 0 ]]; do
    case "${1}" in
      -path)
        arg_required "${@}"
        COMPONENT_PATH=$2
        shift 2
        ;;
      -hydrate_only)
        HYDRATE_ONLY=1
        shift 1
        ;;
      *)
        fatal_with_usage "Unknown option ${1}"
        ;;
    esac
  done
  if [[ ! -n $COMPONENT_PATH ]]; then
    echo "Please provide component path: -path <component path under kubeflow>"
    echo "For example: '-path common/cnrm' will apply resources under kubeflow/common/cnrm."
    exit 1
  fi
}

arg_required() {
  if [[ ! "${2:-}" || "${2:0:1}" = '-' ]]; then
    fatal "Option ${1} requires an argument."
  fi
}


main "${@}"
