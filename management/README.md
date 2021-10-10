## Instruction for Management Cluster

### Prerequisite

Install the necessary tools if not already.

1. Install gcloud SDK and deployment tools:

```    
gcloud components install kubectl kustomize kpt beta
gcloud components update
```

Note: Starting from Kubeflow 1.4, it requires `kpt v1.0.0-beta.6` or above to operate in `kubeflow/gcp-blueprints` repository. gcloud hasn't caught up with this kpt version yet, [install kpt](https://kpt.dev/installation/) separately from https://github.com/GoogleContainerTools/kpt/tags for now. Note that kpt requires docker to be installed.

### Environment Variables

Go to `management/` folder

```
cd management
```

Provide actual value for the following variables in `env.sh`:

```
MGMT_PROJECT=<the project where you deploy your management cluster>
MGMT_DIR=<path to your management cluster configuration directory>
MGMT_NAME=<name of your management cluster>
LOCATION=<location of your management cluster>
```

Run the following commands to set environment variables and kpt setter values.

```
source env.sh
```

```
bash kpt-set.sh
```


### Deploy Management Cluster

Hydrate and apply Management Cluster resources:

```
make apply-cluster
```

Create kubectl cluster Context with name `${MGMT_NAME}`:

```
make create-context
```

Install Cloud Config Connector to Management Cluster:

```
make apply-kcc
```
