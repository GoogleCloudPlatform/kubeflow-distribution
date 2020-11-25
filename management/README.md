# Management Package

This directory contains the configuration needed to setup a management GKE cluster.

Please refer to the latest [docs](https://master.kubeflow.org/docs/gke/deploy/management-setup/)

## Install Instructions

1. Fetch the management package:
    ```bash
    kpt pkg get https://github.com/kubeflow/gcp-blueprints.git/management@v1.2.0 ./
    cd ./management
    # Get upstream package
    make get-pkg
    ```

    Note, paths in all the following instructions assume your current working
    directory is this `./management` folder.

1. Use kpt to set values for the name, project, and location of your management cluster:
    ```bash
    kpt cfg set -R . name ${NAME}
    kpt cfg set -R . gcloud.core.project ${PROJECT}
    kpt cfg set -R . location ${LOCATION}
    ```
    For the values you need to set for management cluster:
    * NAME is the cluster name of your management cluster. Management cluster
    should be a different cluster from your Kubeflow cluster.

        Note, NAME should
        * start with a lowercase character
        * only contain lowercase characters, numbers and `-`
        * end with a number or character
        * contain no more than 18 characters
    * LOCATION is the management cluster's location, you can choose between regional or zonal.
    * PROJECT is the Google Cloud project where you will create this management cluster.

    Running `kpt cfg set` stores values you set in `./instance/Kptfile` and
    `./upstream/management/Kptfile`. Commit the changes to source control to
    preserve your configuration.

    We have two packages with setters: `./instance` and `./upstream/management`.
    The `-R` flag means `--recurse-subpackages`. It sets values recursively in all the
    nested subpackages in current directory `.` in one command.

    You can learn more about `kpt cfg set` in [kpt documentation](https://googlecontainertools.github.io/kpt/reference/cfg/set/), or by running `kpt cfg set --help`.

    Note, you can find out which setters exist in a package and which values were previously set by:
    ```
    kpt cfg list-setters .
    ```

1. Create or apply the management cluster:
    ```bash
    make apply-cluster
    ```
    Optionally, you can verify the management cluster spec before applying it by:
    ```bash
    make hydrate-cluster
    ```
    and look into `./build/cluster` folder.
1. Create a kubectl context for the management cluster, it will be called `${NAME}`:
    ```bash
    make create-context
    ```
1. Install the config connector:
    ```bash
    make apply-kcc
    ```
    Optionally, you can verify the config connector installation before applying it by:
    ```bash
    make hydrate-kcc
    ```
    and look into `./build/cnrm-install-*` folder.

## Customize the installation

To declaratively customize any resource declared in `./upstream/*` folder,
add [Kustomize](https://kustomize.io/) overlays in `./instance` folder.

Some useful links for Kustomize:
* [patchesStrategicMerge](https://kubectl.docs.kubernetes.io/references/kustomize/patchesstrategicmerge/) let you patch any fields of an existing resource using a partial resource definition.
* Reference for all Kustomize features: https://kubectl.docs.kubernetes.io/references/kustomize/.

To get detailed reference for Google Cloud resources, refer to
[Config Connector resources documentation](https://cloud.google.com/config-connector/docs/reference/overview).

To verify whether hydrated resources match your expectation:
```bash
make hydrate-cluster
# or
make hydrate-kcc
```
and refer to hydrated resources in `./build/*`.

To apply your customizations:
```
make apply-cluster
# or
make apply-kcc
```
Note that, some fields in some resources may be immutable. You may need to
manually delete them before applying again.

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
1. Merge your own customizations in `./Makefile` with the latest: https://github.com/kubeflow/gcp-blueprints/blob/master/management/Makefile.
1. Update `./upstream/management` package:
    ```bash
    make update
    ```
1. Use kpt to set user values:
    ```bash
    kpt cfg set -R . name ${NAME}
    kpt cfg set -R . gcloud.core.project ${PROJECT}
    kpt cfg set -R . location ${LOCATION}
    ```
    Note, you can find out which setters exist and which values were previously set by:
    ```
    kpt cfg list-setters .
    ```
1. Apply upgraded config connector:
    ```bash
    make apply-kcc
    ```
1. Check your config connector upgrade is successful:
    ```bash
    # For Kubeflow 1.2, it should be 1.29.0
    $ kubectl get namespace cnrm-system -ojsonpath='{.metadata.annotations.cnrm\.cloud\.google\.com\/version}'
    1.29.0
    ```
