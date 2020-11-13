# Management Blueprint

This directory contains the configuration needed to setup a management GKE cluster.

Please refer to the latest [docs](https://master.kubeflow.org/docs/gke/deploy/management-setup/)

## Upgrade Instructions

### Upgrading management cluster from Kubeflow 1.1 to 1.2

1. Update your `management/Makefile` with the new one https://github.com/kubeflow/gcp-blueprints/blob/master/management/Makefile.
2. Uninstall the Config Connector in management cluster by
    ```bash
    make uninstall-kcc
    ```
    This command uninstalls the config connector installation without removing your resources.
3. Install the upgraded Config Connector by following new installation instructions using the same NAME, LOCATION, PROJECT parameters as before.
