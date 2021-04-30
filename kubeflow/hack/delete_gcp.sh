#!/bin/bash
set -e

echo "Deleting all GCP resources will cause destruction of all services and data on this cluster. Confirm? [y/N]"; 
read REPLY; 
if [[ $REPLY =~ ^[Yy]$ ]]
then 
    kubectl --context=$MGMTCTXT delete -f common/cnrm/$BUILD_DIR
fi
