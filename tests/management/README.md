# End to end testing for management cluster setup

1. Copy `./example.env` to `./.env` and edit values.
2. Run the e2e user install steps
    ```bash
    make
    ```
3. Clean up all the resources created
    ```bash
    make cleanup
    ```

## Test upgrading from Kubeflow v1.1 management cluster

Usage:
```bash
# deploy management cluster in Kubeflow 1.1.0
MANAGEMENT_URL="https://github.com/kubeflow/gcp-blueprints.git/management@v1.1.0" make

# uninstall config connector, but keep all user resources to prepare for upgrade
# to Kubeflow 1.2.0
kubectl delete sts,deploy,po,svc,roles,clusterroles,clusterrolebindings --all-namespaces -l cnrm.cloud.google.com/system=true --wait=true
kubectl delete validatingwebhookconfiguration abandon-on-uninstall.cnrm.cloud.google.com --ignore-not-found --wait=true
kubectl delete validatingwebhookconfiguration validating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true
kubectl delete mutatingwebhookconfiguration mutating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true

# deploy management cluster in Kubeflow 1.2.0
cd ../management
make
```
