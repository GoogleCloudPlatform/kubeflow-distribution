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

1. Install [yq](https://github.com/mikefarah/yq)

   ```
   GO111MODULE=on go get github.com/mikefarah/yq/v3
   ```

   * If you don't have go installed you can download
     a binary from [yq's GitHub releases](https://github.com/mikefarah/yq/releases).

1. Follow these [instructions](https://cloud.google.com/service-mesh/docs/gke-install-new-cluster#download_the_installation_file) to
   install istioctl

## Fetch packages using kpt

1. Fetch the blueprint

   ```
   kpt pkg get https://github.com/kubeflow/gcp-blueprints.git/kubeflow@master ./${PKGNAME}
   ```

   * You can choose any name you would like for the directory ${PKGNAME}

1. Change to the kubeflow directory

   ```
   cd ${PKGNAME}
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

## Configure Kubeflow

There are certain parameters that you must define in order to configure how and where
kubeflow is defined. These are described in the table below.

kpt setter | Description |
-----------|-------------|
mgmt-ctxt | This is the name of the KUBECONFIG context for the management cluster; this kubecontext will be used to create CNRM resources for your Kubeflow deployment. **The context must set the namespace to the namespace in your CNRM cluster where you are creating CNRM resources for the managed project.**|
gcloud.core.project| The project you want to deploy in |
location | The zone or region you want to deploy in |
gcloud.compute.region | The region you are deploying in |
gcloud.compute.zone | The zone to use for zonal resources; must be in gcloud.compute.region |

* Location can be a zone or a region depending on whether you want a regional cluster
  
* The **Makefile** contains a rule `set-values` with approprt `kpt cfg` commands to set the values
  of the parameters

* You need to edit the makefile to set the parameters to the desired values.

   * Note there are multiple invocations of `kpt cfg set` on different directories to
     work around [GoogleContainerTools/kpt#541](https://github.com/GoogleContainerTools/kpt/issues/541)      

* If you haven't previously created an OAuth client for IAP then follow
  the [directions](https://www.kubeflow.org/docs/gke/deploy/oauth-setup/) to setup
  your consent screen and oauth client. 

  * Unfortunately [GKE's BackendConfig](https://cloud.google.com/kubernetes-engine/docs/concepts/backendconfig)
    currently doesn't support creating [IAP OAuth clients programmatically](https://cloud.google.com/iap/docs/programmatic-oauth-clients).

*  Set environment variables with OAuth Client ID and Secret for IAP

   ```
   export CLIENT_ID=
   export CLIENT_SECRET=
   ```

* Invoke the make rule to set the kpt setters

  ```
  make set-values
  ```

## Deploy Kubeflow

To deploy kubeflow just run

   ```
   make apply
   ```

   * If resources can't be created because `webhook.cert-manager.io` is unavailable wait and
     then rerun `make apply`; certmanager can take some time to up and running.


## Update Kubeflow

To update Kubeflow

1. Edit the Makefile and change `MANIFESTS_URL` to point at the version of Kubeflow manifests you
   want to use

   * Refer to the [kpt docs](https://googlecontainertools.github.io/kpt/reference/pkg/) for
     more info about supported dependencies

1. Update the local copies

   
   ```
   make update
   ```

1. Redeploy

   ```
   make apply
   ```

To evaluate the changes before deploying them you can run `make hydrate` and then compare the contents
of `.build` to what is currently deployed.

## Best Practices

The directory `.build` will contain hyrated manifests representing the configurations
that are applied. You should check these into source control.


## Common Problems

1. 502s and backend unhealthy

    * This is often the result of cont configuring ASM correctly (i.e. not specifying the correct
     ServiceMessh or cluster name)   

    * This usually manifests as the istio proxy in the istio ingressgateway from not being able to start
      causing the health check failure. To troubleshoot

      1. Get the pods for the istio-ingressgateway
      
         ```
         kubectl -n istio-system get pods -l app=istio-ingressgateway
         ```

         * Are all containers in the pod started?

      1. Look at the logs for the pods

         ```
         kubectl -n istio-system log ${INGRESS_GATEWAY_POD} -c istio-proxy
         ```

    * Another common cause is failing to enable the ASM services. This will manifest with an error
      like the following in the istio ingress logs.

      ```
      [Envoy (Epoch 0)] [2020-05-06 01:06:09.078][17][warning][config] [bazel-out/k8-opt/bin/external/envoy/source/common/config/_virtual_includes/grpc_stream_lib/common/config/grpc_stream.h:91] gRPC config stream closed: 7, Anthos Service Mesh Certificate Authority API has not been used in project 29647740582 before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/meshca.googleapis.com/overview?project=29647740582 then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry
      ```

    * To enable the services

      ```
      make apply-services
      ```

      * For more info refer to the instructions about enabling services. 

## GitOps(Work In Progress): Using Anthos Config Managment to Install and Manage Kubeflow

### Setting up ACM to manage your project.

You must setup an ACM cluster to manage your project. Typically this entails the following

* Create a management cluster
  * Typically you will want this to be in a different project since it will manage
    multiple projects and have admin privileges that consuemrs of those projects
    shouldn't have

* Follow the instructions to install ACM on that cluster

  * You will also need to install Cloud Config Connector. Starting with Anthos 1.4
    you can use ACM to install Cloud Config Connector. Earlier versions of 
    ACM install a version of Cloud Config COnnector that is to old for Kubeflow.

* In your ACM repo setup a namespace corresponding to the project you will install
  Kubeflow into.

### Deploying Kubeflow

1. Follow the steps in the previous section to configure and hydrate the manifests but do
   not **apply** the manifests.


1. Enable services

   ```
   make apply-services
   ```

   * TODO(jlewi): Can we use CNRM and ACM for this as well.

1. Hydrate the manifests

   ```
   make hydrate
   ```

1. Copy the gcp config resources to the ACM repo that is being used to manage the project
   where Kubeflow is being deployed


   ```
   cp $(BUILD_DIR)/gcp_config $(ACM_MGMT_REPO)/namespaces/$(PROJECT)
   ```

1. Wait for your KF cluster to be deployed

1. Create a context for your new cluster

   ```
   make create-ctxt
   ```

1. Create a directory to use as your ACM repo

   ```
   mkdir acm-repo   
   ```

   * **Important** We currently use an unstructured ACM repository because we don't have a good way
     of reorganizing our K8s resources and files according to the layout required by structured repositories
     e.g. we have files with cluster scoped and namespace scoped resources.

1. Follow the ACM docs to install and configure the ACM operator on your cluster

   * Use a structured repo
   * Do not configure ACM to install Cloud Config Connector


1. Hydrate the configs to be deployed on the management cluster via ACM

   ```
   make acm-gcp
   ```

   * Commit and push those configs

1. Wait for the Kubernetes cluster to be created

1. Create a context

   ```
   make create-ctxt
   ```

1. Set Client ID and Client secret for IAP OAuth

   ```
   export CLIENT_ID=
   export CLIENT_SECRET=
   ```

1. Hydrate the configs to be deployed on the kubeflow cluster via ACM

   ```
   make acm-kubeflow
   ```

1. TODO(fix/test these instructions) Run the custom transform to remove the namespace from cluster scoped resoruces

   ```
   ~/git_kustomize/kustomize/kustomize config run --enable-exec --exec-path ~/git_kubeflow-kfctl/kustomize-fns/remove-namespace/remove-namespace  ./acm-repo/ --stack-trace
   ```

   * TODO(jlewi): Add the appropriate `kpt` command to run this using the docker image.
   
   * Relevant issues:

   * https://github.com/kubeflow/gcp-blueprints/issues/27
   * https://github.com/kubernetes-sigs/kustomize/issues/2498

1. Remove `acm-repo/~g_v1_service_istio-ingressgateway.yaml`
1. Open acm-repo/IngressGateway.yaml and add to the service `istio-ingressgateway` the annotations

   ```
   annotations:
    beta.cloud.google.com/backend-config: '{"ports": {"http2":"iap-backendconfig"}}'
   ```
   * This is a workaround for https://github.com/kubeflow/gcp-blueprints/issues/22

1. In gcloud console find the backend associated with the ingressgateway and change the health check

   * Set port to the node port mapped to the istioingressgateway status port
   * Set health check path to /healthz/ready
   * Relevent instructions https://cloud.google.com/service-mesh/docs/iap-integration

   * TODO(https://github.com/kubeflow/gcp-blueprints/issues/14) Automate this

1. Find the IAP audience for your ingress and update `acm-repo/authentication.istio.io_v1alpha1_policy_ingress-jwt.yaml`
   with it

    * TODO(https://github.com/kubeflow/gcp-blueprints/issues/14): Come up with a better solution

1. Commit and push those configs
   
1. Check the status of the sync

   ```
   nomos --contexts=${KUBEFLOW_CONTEXT} status   
   ```

1. Wait for the istio-system to be created then create the iap secret

   ```
   make iap-secret
   ```

   * Note this is time sensitive; the ingress won't be created until the secret exists
   * The GKE ManagedCertificate can't be provisioned if the ingress doesn't exist
   * If the endpoint doesn't become available within O(5) minutes the GKEManagedCertificate will give up
     on trying to provision the certificate.
