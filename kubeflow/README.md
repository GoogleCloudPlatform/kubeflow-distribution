# Kubeflow Blueprint

This directory contains a blueprint for creating a Kubeflow deployment.

## Prerequisites

You must have created a management cluster and installed Config Connector. 
If you don't have a management cluster follow the [instructions](../management/README.md)
for setting one up. 

Your management cluster must have a namespace setup to administer the GCP project where
Kubeflow will be deployped. Follow the [instructions](../management/README.md) to create
one if you haven't already.


## Install the required tools

1. Install gcloud components

   ```
   gcloud components install kpt anthoscli beta
   gcloud components update
   ```

1. Follow these [instructions](https://cloud.google.com/service-mesh/docs/gke-install-new-cluster#download_the_installation_file) to
   install istioctl

## Fetch packages using kpt

1. Fetch the blueprint

   ```
   kpt pkg get https://github.com/jlewi/kf-templates-gcp.git/kubeflow@master ./
   ```

   * TODO(jlewi): Change to a Kubeflow repo


1. Change to the kubeflow directory

   ```
   cd kubeflow
   ```

1. Fetch Kubeflow manifests

   ```
   make get-pkg
   ```

  * This generates an error per [GoogleContainerTools/kpt#539](https://github.com/GoogleContainerTools/kpt/issues/539) but it looks like
    this can be ignored.

  * TODO(jlewi): This is giving an error like the one below but this can be ignored

    ```
    kpt pkg get https://github.com/jlewi/manifests.git@blueprints ./upstream
    fetching package / from https://github.com/jlewi/manifests to upstream/manifests
    Error: resources must be annotated with config.kubernetes.io/index to be written to files
    ```

## Deploy Kubeflow

1. Set the name of the KUBECONFIG context for the management cluster; this kubecontext will
   be used to create CNRM resources for your Kubeflow deployment.

   ```
   kpt cfg set instance mgmt-ctxt ${MANAGEMENT_CONTEXT}
   ```

   * Follow the [instructions](../README.md) to create a kubecontext for your managment context

   * **Important** The context must set the namespace to the namespace in your CNRM cluster where you are creating
     CNRM resources for the managed project. 

1. Pick a name for the Kubeflow deployment

   ```
   export KFNAME=<some name>
   ```

1. Pick a location for the Kubeflow deployment

   ```
   export LOCATION=<zone or region>
   export ZONE=<zone for disks>
   ```

   * Location can be a zone or a region depending on whether you want a regional cluster
   * We recommend creating regional clusters for higher availability
   * The [cluster management fee](https://cloud.google.com/kubernetes-engine/pricing) is the same for regional
     and zonal clusters

   * TODO(jlewi): Metadata and Pipelines are still using zonal disks what do we have to do make that work with regional clusters? For metadata
     we could use CloudSQL.

1. Set the values for the kubeflow deployment.

   ```
   kpt cfg set ./upstream/manifests/gcp  name ${KFNAME}
   kpt cfg set ./upstream/manifests/gcp gcloud.core.project ${MANAGED_PROJECT}   
   kpt cfg set ./upstream/manifests/gcp  gcloud.compute.zone ${ZONE}

   kpt cfg set ./instance name ${KFNAME}   
   kpt cfg set ./instance location ${LOCATION}
   kpt cfg set ./instance gcloud.core.project ${MANAGED_PROJECT}   
   ```

   * TODO(https://github.com/GoogleContainerTools/kpt/issues/541): If annotations are null kpt chokes. We have such files in manifests which is
     why we have a separate set statement for manifests once we fix that we should be able to just call it once on root

   * TODO(jlewi): Need to figure out what to do about disk for metadata and pipelines when using regional clusters?. Maybe just 
     use Cloud SQL?

1. Set environment variables with OAuth Client ID and Secret for IAP

   ```
   export CLIENT_ID=
   export CLIENT_SECRET=
   ```

   * TODO(jlewi): Add link for instructions on creating an OAuth client id

1. Deploy Kubeflow

   ```
   make apply
   ```

## Common Problems

1. 502s and backend unhealthy

   * This is often the result of cont configuring ASM correctly (i.e. not specifying the correct
     ServiceMessh or cluster name)   

  * This usually manifests as the istio proxy in the istio ingressgateway from not being able to start
    causing the health check failure. 