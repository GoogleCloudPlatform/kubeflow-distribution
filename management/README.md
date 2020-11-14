# Management Blueprint

This directory contains the configuration needed to setup a management GKE cluster.

Please refer to the latest [docs](https://master.kubeflow.org/docs/gke/deploy/management-setup/)

## Install Instructions

1. Fetch the management package:
    ```bash
    kpt pkg get https://github.com/kubeflow/gcp-blueprints.git/management@master ./
    cd ./management
    # Get upstream package
    make get-pkg
    ```
1. Set values for the name, project, and location of your management cluster:
    ```bash
    kpt cfg set ./instance name $NAME
    kpt cfg set ./instance location $LOCATION
    kpt cfg set ./instance gcloud.core.project $PROJECT
    ```
    * NAME is the cluster name of your management cluster. Management cluster
    should be a different cluster from your Kubeflow cluster.

        Note, NAME should
        * start with a lowercase character
        * only contain lowercase characters, numbers and `-`
        * end with a number or character
        * contain no more than 18 characters
    * LOCATION is the management cluster's location, you can choose between regional or zonal.
    * PROJECT is the Google Cloud project where you will create this management cluster.

    It stores values you set in `./instance/Kptfile`. Commit the
    changes to source control to preserve your configuration.

    You can learn more about `kpt cfg set` in [kpt documentation](https://googlecontainertools.github.io/kpt/reference/cfg/set/).

1. Create/apply the management cluster:
    ```bash
    make apply
    ```
1. Create a kubeconfig context for the cluster:
    ```bash
    make create-ctxt
    ```
    The context will be called `${NAME}`.
1. Install the config connector:
    ```bash
    make apply-kcc
    ```

## Clean up Instructions
The following instructions introduce how to clean up all resources created when
installing management cluster and using management cluster to manage Google
Cloud resources in the managed project.

Be cautious, if you want to keep managed Google Cloud resources, you should
finish steps below to keep managed Google Cloud resources before cleaning up
management cluster.

### Clean up or keep managed Google Cloud resources
There are Google Cloud resources managed by Config Connector in the
management cluster after you deploy Kubeflow clusters with this management
cluster.

To delete all the managed Google Cloud resources, delete the managed project
namespace:
```bash
kubectl use-context ${MGMTCTXT}
kubectl delete namespace --wait ${MANAGED_PROJECT}
```
To keep these Google Cloud resources after deleting cnrm resources, you should
add annotation `cnrm.cloud.google.com/deletion-policy: abandon` to all of them
**before** deleting the namespace.

Refer to
[Config Connector: Keeping resources after deletion](https://cloud.google.com/config-connector/docs/how-to/managing-deleting-resources#keeping_resources_after_deletion)
for more details.

### Clean up management cluster Google Cloud resources

To delete the IAM policy binding for the managed project, the Google service account,
and the management cluster:
```bash
gcloud projects remove-iam-policy-binding ${MANAGED_PROJECT} \
    --member=serviceAccount:${NAME}-cnrm-system@${PROJECT}.iam.gserviceaccount.com \
    --role=roles/owner
gcloud --project=${PROJECT} iam service-accounts delete \
    ${NAME}-cnrm-system@${PROJECT}.iam.gserviceaccount.com
gcloud --project=${PROJECT} container clusters delete \
    --zone=${LOCATION} ${NAME}
# Or the following for a regional cluster
# gcloud --project=${PROJECT} container clusters delete \
#     --region=${LOCATION} ${NAME}
```

## Upgrade Instructions

### Upgrading management cluster from Kubeflow v1.1

1. Use your management cluster's kubectl context:
    ```bash
    # Look at all your contexts
    kubectl config get-contexts
    # Select your management cluster's context
    kubectl config use-context ${MGMTCTXT}
    ```
1. Check your existing config connector version:
    ```bash
    # For Kubeflow 1.1, it should be 1.15.0
    $ kubectl get namespace cnrm-system -ojsonpath='{.metadata.annotations.cnrm\.cloud\.google\.com\/version}'
    1.15.0
    ```
1. Uninstall the old config connector in the management cluster:
    ```bash
    kubectl delete sts,deploy,po,svc,roles,clusterroles,clusterrolebindings --all-namespaces -l cnrm.cloud.google.com/system=true --wait=true
    kubectl delete validatingwebhookconfiguration abandon-on-uninstall.cnrm.cloud.google.com --ignore-not-found --wait=true
    kubectl delete validatingwebhookconfiguration validating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true
    kubectl delete mutatingwebhookconfiguration mutating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true
    ```
    These commands uninstall the config connector without removing your resources.
1. Merge your own customizations in `management/Makefile` with the latest: https://github.com/kubeflow/gcp-blueprints/blob/master/management/Makefile. Note, you no longer need to edit the `set-values` rule in the Makefile.
1. Update `upstream/management` package:
    ```bash
    make update
    ```
1. Apply updated cluster and config connector:
    ```bash
    make apply-kcc
    ```
    Note, you do not need to call `kpt cfg set` again because they
    will be called automatically during apply using values stored in
    `management/instance/Kptfile`
1. Check your config connector upgrade is successful:
    ```bash
    # For Kubeflow 1.2, it should be 1.29.0
    $ kubectl get namespace cnrm-system -ojsonpath='{.metadata.annotations.cnrm\.cloud\.google\.com\/version}'
    1.29.0
    ```
