# Management Blueprint

This directory contains the configuration needed to setup a management GKE cluster.

This management cluster must run [Cloud Config Connector](https://cloud.google.com/config-connector/docs/overview). The management cluster is configured in namespace mode.
Each namespace is associated with a Google Service Account which has owner permissions on 
one or more GCP projects. You can then create GCP resources by creating CNRM resources
in that namespace.

Optionally, the cluster can be configured with [Anthos Config Managmenet](https://cloud.google.com/anthos-config-management/docs) 
to manage GCP infrastructure using GitOps.

## Install the required tools

1. Install gcloud components

   ```
   gcloud components install kpt anthoscli beta
   gcloud components update
   ```

## Setting up the management cluster


1. Fetch the management blueprint

   ```
   kpt pkg get https://github.com/kubeflow/gcp-blueprints.git/management@master ./
   ```

1. Fetch the upstream manifests

   ```
   cd ./management
   make get-pkg
   ```

   * TODO(jlewi): This is giving an error like the one below but this can be ignored

    ```
    kpt pkg get https://github.com/jlewi/manifests.git@blueprints ./upstream
    fetching package / from https://github.com/jlewi/manifests to upstream/manifests
    Error: resources must be annotated with config.kubernetes.io/index to be written to files
    ```

1. Pick a name for the management cluster

   ```
   export MGMT_NAME=<some name>
   ```

1. Pick a location for the Kubeflow deployment

   ```
   export LOCATION=<zone or region>
   export PROJECT=<project>   
   ```

1. Set the name for the management resources in the upstream kustomize package

   ```
   kpt cfg set ./upstream name $(MGMT_NAME)   
   ```

1. Set the same names in the instance kustomize package defining patches

   ```   
   
   kpt cfg set ./instance name $(MGMT_NAME)   
   kpt cfg set ./instance location $(LOCATION)
   kpt cfg set ./instance gcloud.core.project $(PROJECT)   
   ```

   * This directory defines kustomize overlays applied to `upstream/management`

   * The names of the CNRM resources need to be set in both the base 
     package and the overlays

1. Hydrate and apply the manifests to create the cluster

   ```
   make apply
   ```

1. Create a kubeconfig context for the cluster

   ```
   make create-ctxt
   ```

1. Install the CNRM system components

   ```
   make install-kcc
   ```

### Setup KCC Namespace For Each Project

You will configure Config Connector in [Namespaced Mode](https://cloud.google.com/config-connector/docs/concepts/installation-types#namespaced_mode). This means

* There will be a separate namespace for each GCP project under management
* CNRM resources will be created in the namespace matching the GCP project
  in which the resource lives.
* There will be multiple instances of the CNRM controller each managing
  resources in a different namespace
* Each CNRM controller can use a different K8s account which can be bound
  through workload identity to a different GCP Service Account with permissions to manage the project

For each project you want to setup follow the instructions below.

1. Create a copy of the per namespace/project resources

   ```
   cp -r ./instance/install-per-project ./instance/cnrm-install-${MANAGED_PROJECT}
   ```
1. Set the project to be mananged

   ```
   kpt cfg set cnrm-install-${MANAGED_PROJECT} managed_project ${MANAGED_PROJECT}
   ```

1. Set the host project where kcc is running

   ```
   kpt cfg set instance/cnrm-install-${MANAGED_PROJECT} managed_gsa_name ${MANAGED_GSA_NAME}
   kpt cfg set instance/cnrm-install-${MANAGED_PROJECT} host_project ${HOST_PROJECT}
   kpt cfg set instance/cnrm-install-${MANAGED_PROJECt} host_id_pool ${HOST_PROJECT}.svc.id.goog
   ```

   * **MANAGED_SA_NAME** Name for the Google Service Account (GSA) to create to be used
     with Cloud Config Connector to create resources in the managed project
   * host_id_pool should be the workload identity pool used for the host project

1. Apply this manifest to the mgmt cluster


   ```
   kubectl --context=$(MGMTCTXT) apply -f ./instance/cnrm-install-${PROJECT}/per-namespace-components.yaml
   ```

1. Create the GSA and workload identity binding

   ```
   anthoscli apply --project=${MANAGED_PROJECT} -f ./instance/cnrm-install-${PROJECT}/service_account.yaml
   ```

1. anthoscli doesn't support IAMPolicyMember resources yet so we use this as a workaround
   to make the newly created GSA an owner of the hosted project

   ```
   gcloud projects add-iam-policy-binding ${MANAGED_PROJECT} \
    --member=serviceAccount:${MANAGED_GSA_NAME}@${MANAGED_PROJECT}.iam.gserviceaccount.com  \
    --role roles/owner
   ```

## References

[CNRM Reference Documentation](https://cloud.google.com/config-connector/docs/reference/resources) 
