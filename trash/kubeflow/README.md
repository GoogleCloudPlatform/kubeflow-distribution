# Kubeflow Blueprint

This directory contains a blueprint for creating a Kubeflow deployment.

## Installing Kubeflow

Please refer to the instructions on the [website](https://master.kubeflow.org/docs/gke/deploy/deploy-cli/).


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

* Follow the [instructions](https://cloud.google.com/anthos-config-management/docs/how-to/installing) to install ACM on that cluster

* Initialize an ACM repo for your management cluster

  ```
  nomos init --path=${ACM_MGMT_REPO}
  ```

* In your ACM repo setup a namespace corresponding to the project you will install
  Kubeflow into.

  * Create the directory **${ACM_MGMT_REPO}/namespaces/${PROJECT}**

  * Add a file **namespace.yaml** That looks like 

    ```
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${PROJECT}
    ```

  * If you are using ACM to actually create the project then add a project.yaml file that looks like


    ```
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    metadata:
      annotations:
        # Set this to the id of the folder to create your project or delete this line
        # if you aren't using folders.
        cnrm.cloud.google.com/folder-id: "${FOLDER}"    
        cnrm.cloud.google.com/auto-create-network: "true"
      # Set this to your Project
      name: ${PROJECT}
    spec:
      # Set this to your Project
      name: ${PROJECT}      
      billingAccountRef:
        # Set this to your billing account
        external: "${BILLING_ACCOUNT}"
    ```

### Deploying Kubeflow

1. Follow the steps in the [directions](https://master.kubeflow.org/docs/gke/deploy/deploy-cli/#configure-kubeflow)
   to configure Kubeflow

   * Edit your Makefile as described to fill in the **set-values** rule with the actual values for your deployment
  
1. Edit your Makefile to set the variables **ACM_MGMT_REPO** and **ACM_KF_REPO** to the
   paths of your ACM repos for your management and KF repositories.


1. Hydrate the manifests

   ```
   make acm-gcp
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
   nomos init --path=${ACM_KF_REPO}  
   ```

1. Follow the ACM docs to install and configure the ACM operator on your cluster

   * Use **structured** repo 
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

1. In the Cloud Console find the backend associated with the ingress gateway and change the health check

   * Set port to the node port mapped to the istioingressgateway status port
   * Set health check path to /healthz/ready
   * Relevent instructions https://cloud.google.com/service-mesh/docs/iap-integration

   * TODO(https://github.com/kubeflow/gcp-blueprints/issues/14) Automate this


1. Find the IAP audience for your ingress and create a patch for it

    * Create the file `${KFDIR}/instance/kustomize/iap-ingress/ingress-authentication-policy.yaml` with the contents

      ```
      apiVersion: authentication.istio.io/v1alpha1
      kind: Policy
      metadata:  
        name: ingress-jwt
      spec:
        origins:
        - jwt:
            audiences:
            - <Your IAP OAuth client audience>
            issuer: https://cloud.google.com/iap
            jwksUri: https://www.gstatic.com/iap/verify/public_key-jwk
            jwtHeaders:
            - x-goog-iap-jwt-assertion
            trigger_rules:
            - excluded_paths:
              - exact: /healthz/ready
      ```

    * Run the following command to add it as a patch

      ```
      cd ${KFDIR}/instance/kustomize/iap-ingress/
      kustomize edit add patch ingress-authentication-policy.yaml
      ```

    * Change the audience to the OAuth client audience
    * TODO(https://github.com/kubeflow/gcp-blueprints/issues/14): Come up with a better solution

1. Create a patch for the ISTIO gateway for the notebook controller

   * Create the file `./${KFDIR}/instance/kustomize/kubeflow-apps/notebook-controller-patch.yaml` with the contents

     ```
      apiVersion: v1
      data:
        ISTIO_GATEWAY: istio-system/ingressgateway
      kind: ConfigMap
      metadata:
        name: notebook-controller-config
     ```

   * Run the following command to add it as a patch

      ```
      cd ${KFDIR}/instance/kustomize/kubeflow-apps/
      kustomize edit add patch notebook-controller-patch.yaml
      ```

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


## Troubleshooting ACM

* Use the nomos command to get information about files failing validation.

  ```
  nomos vet --source-format=unstructured --no-api-server-check --path=${ACM_REPO_PATH}
  ```
