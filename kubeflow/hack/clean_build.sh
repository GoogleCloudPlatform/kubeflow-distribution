#!/bin/bash
set -e

# Clean certain component's build directory content
# BUILD_DIR=$(RESOURCE_LOCATION) ./clean_build -path <component path under kubeflow>


COMPONENT_PATH=""

main() {
  parse_args "${@}"

  [ ! -n "$BUILD_DIR" ] && BUILD_DIR=./build
  echo "Build directory envrionment variable: $BUILD_DIR"
  component_build_dir=./$COMPONENT_PATH/$BUILD_DIR
  echo "Removing component build directory: $component_build_dir"
  rm -rf $component_build_dir
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
      *)
        fatal_with_usage "Unknown option ${1}"
        ;;
    esac
  done
  if [ ! -n $COMPONENT_PATH ]; then
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
