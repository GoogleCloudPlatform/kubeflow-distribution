The makefile provides a quick way to install management cluster in Kubeflow
1.1.0, so that we can verify upgrade experience.

Usage:
```bash
# deploy management cluster in Kubeflow 1.1.0
make test
# uninstall config connector, but keep all user resources to prepare for upgrade
# to Kubeflow 1.2.0
make uninstall-kcc
# deploy management cluster in Kubeflow 1.2.0
cd ../management
make test
```
