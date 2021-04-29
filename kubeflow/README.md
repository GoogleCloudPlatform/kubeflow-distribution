## Instruction for Kubeflow Cluster

This instruction is for the deployment steps to create Kubeflow Cluster on GCP. This instruction assumes that you have already created [Management Cluster](../management/README.md) for creating Google Cloud related resources. And have [authorized Config Connector](https://www.kubeflow.org/docs/distributions/gke/deploy/management-setup/#authorize-cloud-config-connector-for-each-managed-project) to manage Kubeflow project.

### Prerequisite


Install the necessary tools if not already.

1. Install gcloud SDK and deployment tools:

```
gcloud components install kubectl kpt beta
gcloud components update
```

2. Install Kustomize

```
# Detect your OS and download corresponding latest Kustomize binary
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# Add the kustomize package to your $PATH env variable
sudo mv ./kustomize /usr/local/bin/kustomize
```

3. Install yq v3

Follow the yq v3 [installation instruction](https://github.com/mikefarah/yq#install). For example, if using wget, you can run following commands: 

```
sudo wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
```

4. Install jq https://stedolan.github.io/jq/, for example, we can run the following command on Linux:

```
sudo apt install jq
```

### Fetch packages

Go to Kubeflow Cluster

```
cd kubeflow
```

`kubeflow/gcp-blueprints` utilizes upstream repositority `kubeflow/manifests` for versioned manifests of multiple Kubeflow components. We need to first fetch upstream manifests by running command:

```
bash ./pull_upstream.sh
```


### Environment Variables



Provide actual value for the following variables in `env.sh`:

```
KF_NAME=<kubeflow-cluster-name>
KF_PROJECT=<gcp-project-id>
KF_DIR=<current-kubeflow-directory-path>
MGMT_NAME=<management-cluster-name>
MGMTCTXT=${MGMT_NAME}
LOCATION=<zone>
```

Provide the actual value for the following variables in `kpt-set.sh`:

```
kpt cfg set -R .  gcloud.project.projectNumber <KF_PROJECT_NUMBER>
kpt cfg set -R .  email <YOUR_EMAIL_ADDRESS>
```

Run the following commands to set environment variables and kpt setter

```
source env.sh
```

```
bash kpt-set.sh
```

Set the Client ID and Secret from IAP Oauth step:

```
export CLIENT_ID=<Your CLIENT_ID>
export CLIENT_SECRET=<Your CLIENT_SECRET>
```

### Deploy Kubeflow Cluster


Run following command to login

```
gcloud auth login
```


Set the google project you want to deploy.
```
gcloud config set project $KF_PROJECT
```


Set default cluster location
```
gcloud config set compute/zone $LOCATION
```

Deploy Kubeflow cluster, required Google Cloud resources and all Kubeflow components:

```
make apply-all
```

## Other Commands


### Hydrate all manifests but not apply them

If you want to check the resource in `/build` directories before applying them. You can use `hydrate-all` before running `apply-all`:

```
make hydrate-all
```

### Clean up the hydration result from all components

After hydration or apply, you will have `build` folder in each component for manifest yaml files. If you want to cleean them up, you can run:

```
make clean-build
```

### Uninstall the whole Kubeflow cluster

Deleting cluster itself doesn't necessarily remove all resources created by this instruction. You can run the following command to clean them up:

```
make delete-gcp
```
