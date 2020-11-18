# Configuration for installing Cloud Config Connector in the management cluster.

Configs are a copy of the CNRM operator install with necessary Google Cloud
resources to set up workload identity binding. (see [docs](https://cloud.google.com/config-connector/docs/how-to/advanced-install#manual)).

To update:

1. Download the the latest install bundle listed on (https://cloud.google.com/config-connector/docs/how-to/advanced-install#manual).

1. Untar and replace the file `install-system/configconnector-operator.yaml`.
