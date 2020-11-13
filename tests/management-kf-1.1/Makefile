include ../../management/Makefile

# Kubeflow 1.1 management package url
MANAGEMENT_URL=https://github.com/kubeflow/gcp-blueprints.git/management@v1.1.0

# Uninstall config connector while keeping user resources.
# After uninstallation, install a new version of config connector and it will pick up
# all user resources.
uninstall-kcc:
	kubectl delete sts,deploy,po,svc,roles,clusterroles,clusterrolebindings --all-namespaces -l cnrm.cloud.google.com/system=true --wait=true
	kubectl delete validatingwebhookconfiguration abandon-on-uninstall.cnrm.cloud.google.com --ignore-not-found --wait=true
	kubectl delete validatingwebhookconfiguration validating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true
	kubectl delete mutatingwebhookconfiguration mutating-webhook.cnrm.cloud.google.com --ignore-not-found --wait=true
