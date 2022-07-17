## Kubeflow on Google Cloud

The Kubeflow on Google Cloud distribution versioning is following the versioning of [kubeflow/manifests](https://github.com/kubeflow/manifests).

### Unreleased

### v1.6.0

* Upgrade cert-manger to v1.5.0 (#372)
* Upgrade knative to v1.2 (#373)
* Update CHANGELOG.md (#)
* Fix ASM/istio ingress gateway issue (#371)

### v1.5.1

* Upgrade ASM to v1.13 (#369)
* Fixed KServe issues with dashboard (#362) and directory(#361).
* Increased the maximum length of Kubeflow cluster name (#359).
* Moved RequestAuthentication policy creation to iap-enabler to improve GitOps friendliness (#364).
* Renamed `${name}-kfp-cloudsql` service account into `${name}-sql` to fix the name length restriction (#358)

### v1.5.0

* Upgrade Kubeflow components versions as listed in components versions table
* Integrated with Config Controller, simplified management cluster maintenance cost, there is no need to manually upgrade Config Connector CRD.
* Switch from kfserving to KServe as default serving component, you can switch back to kfserving in config.yaml.
* Fixed cloudsqlproxy issue with livenessProbe configuration.

### v1.4.1

* Upgrade: Integrate with Kubeflow 1.4.1 manifests (kubeflow/manifests#2084)
* Fix: Change cloud endpoint images destination (#343)
* Fix: Use yq4 in iap-ingress Makefile.

### v1.4.0

* Upgrade Kubeflow components versions as listed in components versions table
* Removed GKE 1.18 image version and k8s runtime pin, now GKE version is default to Stable channel.
* Set Emissary Executor as default Argo Workflow executor for Kubeflow Pipelines.
* Upgraded kpt versions from 0.X.X to 1.0.0-beta.6.
* Upgraded yq from v3 to v4.
* Upgraded ASM(Anthos Service Mesh) to 1.10.4-asm.6.
* Unblocked KFSserving usage by removing commonLabels from kustomization patch #298 #324.
* Integrated with KFServing Web App UI.
* Integrated with unified operator: training-operator.
* Simplified deployment: Removed requirement for independent installation of yq, jq, kustomize, kpt.

### v1.3.1

* Change folder name istio-1-9-0 to istio-1-9

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

Other items can be found in [gcp-blueprints 1.3 release](https://github.com/kubeflow/gcp-blueprints/projects/2) and [Kubeflow Pipelines 1.3 release](https://github.com/kubeflow/pipelines/projects/12).
