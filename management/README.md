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
1. Edit `management/set-values.sh` to set values for the name, project, and location of your management cluster:

    * NAME is the cluster name of your management cluster. Management cluster
    should be a different cluster from your Kubeflow cluster.

        Note, NAME should
        * start with a lowercase character
        * only contain lowercase characters, numbers and `-`
        * end with a number or character
        * contain no more than 18 characters
    * LOCATION is the management cluster's location, you can choose between regional or zonal.
    * PROJECT is the Google Cloud project where you will create this management cluster.

    Running `set-values.sh` stores values you set in `./instance/Kptfile`. Commit the
    changes to source control to preserve your configuration.

    You can learn more about `kpt cfg set` in [kpt documentation](https://googlecontainertools.github.io/kpt/reference/cfg/set/).

1. Create/apply the management cluster:
    ```bash
    make apply-cluster
    ```
    Optionally, you can verify the management cluster spec before applying it by:
    ```bash
    make hydrate-cluster
    ```
    and look into `build/cluster` folder.
1. Create a kubectl context for the management cluster, it will be called `${NAME}`:
    ```bash
    make create-ctxt
    ```
1. Install the config connector:
    ```bash
    make apply-kcc
    ```
    Optionally, you can verify the config connector installation before applying it by:
    ```bash
    make hydrate-kcc
    ```
    and look into `build/cnrm-install-*` folder.

## Clean up Instructions
The following instructions introduce how to clean up all resources created when
installing management cluster and using management cluster to manage Google
Cloud resources in the managed project.

### Delete or keep managed Google Cloud resources
There are Google Cloud resources managed by Config Connector in the
management cluster after you deploy Kubeflow clusters with this management
cluster.

To delete all the managed Google Cloud resources, delete the managed project
namespace:
```bash
kubectl use-context ${MGMTCTXT}
kubectl delete namespace --wait ${MANAGED_PROJECT}
```

To keep all the managed Google Cloud resources, you can delete the management
cluster directly.

If you need fine-grained control, refer to
[Config Connector: Keeping resources after deletion](https://cloud.google.com/config-connector/docs/how-to/managing-deleting-resources#keeping_resources_after_deletion)
for more details.

After deleting cnrm resources for a managed project, you can revoke IAM perssion
that let the management cluster manage the project:
```bash
gcloud projects remove-iam-policy-binding ${MANAGED_PROJECT} \
    --member=serviceAccount:${NAME}-cnrm-system@${PROJECT}.iam.gserviceaccount.com \
    --role=roles/owner
```

### Delete management cluster

To delete the Google service account, and the management cluster:
```bash
make delete-cluster
```

Note, after deleting the management cluster, all the managed Google Cloud
resources will be kept. You are responsible for managing them by yourself.

You can create a management cluster to manage them again if you apply the same
cnrm resources. Refer to https://cloud.google.com/config-connector/docs/how-to/managing-deleting-resources#acquiring_a_dataset.

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
    # For Kubeflow 1.1, it should be 1.15.1
    $ kubectl get namespace cnrm-system -ojsonpath='{.metadata.annotations.cnrm\.cloud\.google\.com\/version}'
    1.15.1
    ```
1. Uninstall the old config connector in the management cluster:
    ```bash
    kubectl delete sts,deploy,po,svc,roles,clusterroles,clusterrolebindings --all-namespaces -l cnrm.cloud.google.com/system=true --wait=true
    kubectl delete validatingwebhookconfiguration abandon-on-uninstall.cnrm.cloud.google.com --ignore-not-found --wait=true
    kubectl delete validatingwebhookconfiguration validating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true
    kubectl delete mutatingwebhookconfiguration mutating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true
    ```
    These commands uninstall the config connector without removing your resources.
1. Merge your own customizations in `management/Makefile` with the latest: https://github.com/kubeflow/gcp-blueprints/blob/master/management/Makefile. Note, you should download https://github.com/kubeflow/gcp-blueprints/blob/master/management/set-values.sh and edit values in `set-values.sh`.
1. Update `upstream/management` package:
    ```bash
    make update
    ```
1. Apply updated config connector:
    ```bash
    make apply-kcc
    ```
1. Check your config connector upgrade is successful:
    ```bash
    # For Kubeflow 1.2, it should be 1.29.0
    $ kubectl get namespace cnrm-system -ojsonpath='{.metadata.annotations.cnrm\.cloud\.google\.com\/version}'
    1.29.0
    ```
