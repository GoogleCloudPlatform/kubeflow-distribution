# Configuration for installing Cloud Config Connector in the management cluster.

> **Note**:
> Starting with Kubeflow 1.5, we leveraged the managed version of Config Connector, which is called [Config Controller](https://cloud.google.com/anthos-config-management/docs/concepts/config-controller-overview). As it does not require manual upgrading, ignore the upgrade instructions below if you use a default deployment of the management cluster through Config Controller setup process.

Configs are a copy of the CNRM operator install with necessary Google Cloud resources to set up workload identity binding. (see [docs](https://cloud.google.com/config-connector/docs/how-to/advanced-install#manual)).

To update:

1. Download the the latest install bundle listed on (https://cloud.google.com/config-connector/docs/how-to/advanced-install#manual).

1. Untar and replace the file `install-system/configconnector-operator.yaml`.
