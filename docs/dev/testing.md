# Testing 

This page is intended for blueprint developers and covers testing.

## Auto Deployed Clusters

[Kubeflow's auto-deploy infrastructure](https://github.com/kubeflow/testing/tree/master/test-infra/auto-deploy)
is used to regular create fresh Kubeflow deployments from the tip of the master branch
and any release branches.

[Quick Links For Auto Deploy Infra](https://github.com/kubeflow/testing/tree/master/test-infra/auto-deploy#quick-links)

[Dashboard of auto deployments](https://kf-ci-v1.endpoints.kubeflow-ci.cloud.goog/auto_deploy/)

We use prow to regularly run tests against the auto-deployed instances to verify they are healthy.
