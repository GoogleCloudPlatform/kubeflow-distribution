#!/bin/bash
#
# A helper script to create OAuth clients using the caller's GCP project.
#

if [[ ! -n $ADMIN_EMAIL ]]; then
  echo "Please provide a value for ADMIN_EMAIL"
  exit 1
fi

if [[ ! -n $NAME ]]; then
  echo "Please provide a value for NAME"
  exit 1
fi

BRAND_ID="`gcloud iap oauth-brands list | grep 'name: '`"

if [[ ! -n $BRAND_ID ]]; then
  echo 'OAuth brand does not exist, creating new one...'
  BRAND_ID="`gcloud iap oauth-brands create --application_title=kubeflow --support_email=$ADMIN_EMAIL | grep 'name: '`"
fi

BRAND_ID=$(echo $BRAND_ID | sed -e "s/name: //g")

CLIENT_OUTPUT=`gcloud iap oauth-clients create $BRAND_ID --display_name=$NAME`

export CLIENT_ID=$(echo $CLIENT_OUTPUT | sed 's/.*identityAwareProxyClients\/\([^ ]*\).*/\1/')
echo "CLIENT_ID=$CLIENT_ID"

export CLIENT_SECRET=$(echo $CLIENT_OUTPUT | sed 's/.*secret: \([^ ]*\).*/\1/')
echo "CLIENT_SECRET=$CLIENT_SECRET"
