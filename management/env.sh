# This guide assumes the following convention:

# The ${MGMT_PROJECT} environment variable contains the Google Cloud project ID where management cluster is deployed to.

# The ${MGMT_DIR} environment variable contains the path to your management directory, which holds your management cluster 
# configuration files. For example, ~/gcp-blueprints/management/. You can choose any path you would like for the directory ${MGMT_DIR}.

# To continuously manage the management cluster, you are recommended to check the management configuration directory into source control.

# ${MGMT_NAME} is the cluster name of your management cluster and the prefix for other Google Cloud resources created in the deployment process. Management cluster should be a different cluster from your Kubeflow cluster.

# Note, ${MGMT_NAME} should

# start with a lowercase letter
# only contain lowercase letters, numbers and -
# end with a number or a letter
# contain no more than 18 characters
# The ${LOCATION} environment variable contains the location of your management cluster. you can choose between regional or zonal, see Available regions and zones.


export MGMT_PROJECT=cmp-development
export MGMT_DIR=~/dev/k8s-competera/management_cluster/gcp-blueprints/management
export MGMT_NAME=cmp-air # no longer than 18 characters
export LOCATION=europe-west1-b
