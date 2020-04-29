# Kubeflow Blueprint

Blueprints for Kubeflow.

Kubeflow is deployed as follows

* A mangement cluster is setup using the manifests in **management**
  * The management cluster runs KCC and optionally ConfigSync
  * The management cluster is used to create all GCP resources for Kubeflow (e.g. the GKE cluster)
  * A single management cluster could be used for multiple projects or multiple KF deployments

* Once the Kubeflow cluster is created we use kustomize to deploy the KF applications on it.

For more information about blueprints refer to the [kpt blueprint guide](https://googlecontainertools.github.io/kpt/guides/producer/blueprint/)

## Getting Started

1. Use the [management](./management/README.md) blueprint to spin up a management
   cluster
1. Use the [kubeflow](./kubeflow/README.md) blueprint to create a Kubeflow deployment.