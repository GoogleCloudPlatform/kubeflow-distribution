#!/bin/bash
#
# A simple helper script to set kpt setters for both instance and upstream package.
#
# Please edit the variables $NAME, $PROJECT, $LOCATION!
# NAME: The cluster name of the management cluster. Warning, it should be different
#   from your Kubeflow cluster.
# LOCATION: Location of the management cluster. You can choose either regional or zonal.
# PROJECT: Google Cloud project where this management cluster is created in.
#
# The values you set will be stored in ./instance/Kptfile and
# ./upstream/management/Kptfile, so they will be preserved if you commit the
# changes to source control.

set -ex

for package in (./instance ./upstream/management)
do
    kpt cfg set $package name $NAME
    kpt cfg set $package gcloud.core.project $PROJECT
    kpt cfg set $package location $LOCATION
done
