# Kubeflow Blueprint On Google Cloud

Follow the instruction to deploy full fledged Kubeflow on Google Cloud Kubernetes cluster. 

Kubeflow is deployed as follows

* Deploy mangement cluster using the manifests in **management**.
  * The management cluster runs KCC and optionally ConfigSync
  * The management cluster is used to create all Google Cloud resources for Kubeflow (e.g. the GKE cluster)
  * A single management cluster could be used for multiple projects or multiple KF deployments

* Deploy Kubeflow cluster using the manifests in **kubeflow**.
  * kubeflow contains kustomization rule for each component.
  * Component manifests is pulled from upstream `kubeflow/manifests` repository to individual folder's `upstream/` directory.
  * `Makefile` uses kustomize and kubectl to generate and apply resources.


For more information about packages refer to the [kpt packages guide](https://googlecontainertools.github.io/kpt/guides/producer/packages/)

## Getting Started

1. Use the [management](./management/README.md) blueprint to spin up a management
   cluster
1. Use the [kubeflow](./kubeflow/README.md) blueprint to create a Kubeflow deployment.

## Development

### Test Grid

* [Master Periodic](https://k8s-testgrid.appspot.com/sig-big-data#kubeflow-gcp-blueprints-master&group-by-hierarchy-pattern=%5B%5Cw-%5D%2B)
* [Master Presubmit](https://k8s-testgrid.appspot.com/sig-big-data#kubeflow-gcp-blueprints-presubmit&group-by-hierarchy-pattern=%5B%5Cw-%5D%2B)
* [Master Postsubmit](https://k8s-testgrid.appspot.com/sig-big-data#kubeflow-gcp-blueprints-postsubmit&group-by-hierarchy-pattern=%5B%5Cw-%5D%2B)
