
# Use kpt to set kustomize values

kpt cfg set -R .  gke.private false

kpt cfg set -R .  mgmt-ctxt ${MGMT_NAME}

kpt cfg set -R .  name ${KF_NAME}
kpt cfg set -R .  gcloud.project.projectNumber <KF_PROJECT_NUMBER>
kpt cfg set -R .  gcloud.core.project ${KF_PROJECT}
kpt cfg set -R .  gcloud.compute.zone ${LOCATION}
kpt cfg set -R .  location ${LOCATION}
kpt cfg set -R .  log-firewalls false

kpt cfg set -R .  email <YOUR_EMAIL_ADDRESS>
