## Instruction for Kubeflow Cluster

This instruction is for the deployment steps to create Kubeflow Cluster on GCP. This instruction assumes that you have already created [Management Cluster](../management/README.md) for creating Google Cloud related resources. And have [authorized Config Connector](https://www.kubeflow.org/docs/distributions/gke/deploy/management-setup/#authorize-cloud-config-connector-for-each-managed-project) to manage Kubeflow project.

### Prerequisite


Install the necessary tools if not already.

1. Install gcloud SDK and deployment tools:

```bash
gcloud components install kubectl kpt beta
gcloud components update
```

2. Install Kustomize:

```bash
# Detect your OS and download corresponding latest Kustomize binary
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# Add the kustomize package to your $PATH env variable
sudo mv ./kustomize /usr/local/bin/kustomize
```

3. Install yq v3

Follow the yq v3 [installation instruction](https://github.com/mikefarah/yq#install). For example, if using wget, you can run following commands: 

```bash
sudo wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
```

4. Install jq https://stedolan.github.io/jq/, for example, we can run the following command on Linux:

```bash
sudo apt install jq
```

### Fetch packages

Go to Kubeflow Cluster

```bash
cd kubeflow
```

`kubeflow/gcp-blueprints` utilizes upstream repositority `kubeflow/manifests` for versioned manifests of multiple Kubeflow components. We need to first fetch upstream manifests by running command:

```bash
bash ./pull_upstream.sh
```

### Environment Variables

Provide actual value for the following variables in `env.sh`, refer to detailed
documentation in env.sh.

Set the environment variables in your shell:

```bash
source env.sh
```

Configure kpt setters as environement variables in packages:

```bash
bash kpt-set.sh
```

Set the Client ID and Secret from IAP OAuth step:

```bash
export CLIENT_ID=<Your CLIENT_ID>
export CLIENT_SECRET=<Your CLIENT_SECRET>
```

### Deploy Kubeflow Cluster


Run following command to login:

```bash
gcloud auth login
```

Set the google project you want to deploy.
```bash
gcloud config set project $KF_PROJECT
```

Deploy Kubeflow cluster, required Google Cloud resources and all Kubeflow components:

```bash
make apply
```

## Other Commands

Reminder, all the following commands assume you already set up env vars by:

```bash
source env.sh
```

### Hydrate all manifests but not apply them

If you want to check the resources in `build` directories first, run the
following command before `make apply`:

```bash
make hydrate
```

### Clean up the hydration result from all components

After hydration or apply, you will have `build` folder in each component for manifest yaml files. If you want to clean them up, you can run:

```bash
make clean-build
```

### Uninstall the whole Kubeflow cluster

Deleting cluster itself doesn't necessarily remove all resources created by this instruction. You can run the following command to clean them up:

```bash
make delete
```

#### Delete managed storage

Managed storage -- CloudSQL and Cloud Storage (GCS) bucket contains Kubeflow
Pipelines data, they are not deleted by default when deleting the Kubeflow
cluster, because you can re-deploy a new Kubeflow cluster using existing managed
storages.

Run the following commands to delete managed storage:

```bash
cd common/managed-storage
make delete
```
