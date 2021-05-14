## Kubeflow on Google Cloud

The Kubeflow on Google Cloud distribution versioning is following the versioning of [kubeflow/manifests](https://github.com/kubeflow/manifests).

### Unreleased

### v1.3.0

*  Refactor manifest organizing approach and abandon `instance` folder structure.
*  Create individual component directories, which contains kustomization.yaml, patches and upstream location to enable independent component deployment.
*  Upgrade Kubernetes version of deployment to v1.18 and use STABLE release channel on Google Cloud.
*  Upgrade default machine type for N1 to E2.
*  Upgrade ASM (Anthos Service Mesh) from v1.4 to v1.9.3. https://github.com/kubeflow/gcp-blueprints/issues/144
*  Enable using Google Cloud Storage options (Cloud SQL, GCS bucket) for Kubeflow Pipelines v1.5.0. https://github.com/kubeflow/pipelines/issues/4356
*  Add support for K8s RBAC via SubjectAccessReview on Kubeflow Pipelines. https://github.com/kubeflow/pipelines/issues/3513
*  Upgrade KNative v0.22, cert-manager v0.13, for integrating with new version of KFServing v0.5.1.
*  Upgrade to Kustomize 4+ and remove the need of specifying no load restrictor.
*  Update profile controller to allow kustomization of namespace label injection. https://github.com/kubeflow/kubeflow/pull/5761
*  Rework of Kubeflow on Google Cloud documentations.

Other items can be found in [gcp-blueprints 1.3 release](https://github.com/kubeflow/gcp-blueprints/projects/2) and [Kubeflow Pipelines 1.3 release ](https://github.com/kubeflow/pipelines/projects/12).
