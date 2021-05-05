## Instruction for Management Cluster

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
