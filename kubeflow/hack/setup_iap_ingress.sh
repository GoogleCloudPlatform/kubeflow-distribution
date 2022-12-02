#!/bin/bash
#
# A helper script to create IAP ingress using the caller's GCP project.
# The script will first create OAuth client and brand if these are
# not provided.
#
# To find more information about the commands, please see
# https://cloud.google.com/iap/docs/programmatic-oauth-clients.
#
#
if [[ ! -n $KFCTXT ]]; then
  echo "Please provide a value for KFCTXT"
  exit 1
fi

if [[ ! -n $CLIENT_ID && ! -n $CLIENT_SECRET ]]; then
  if [[ ! -n $ADMIN_EMAIL ]]; then
    echo "Please provide a value for ADMIN_EMAIL"
    exit 1
  fi

  if [[ ! -n $OAUTH_NAME ]]; then
    echo "Please provide a value for OAUTH_NAME"
    exit 1
  fi

  BRAND_ID="`gcloud iap oauth-brands list | grep 'name: '`"

  if [[ ! -n $BRAND_ID ]]; then
    echo 'OAuth brand does not exist, creating new one...'
    BRAND_ID="`gcloud iap oauth-brands create --application_title=kubeflow --support_email=$ADMIN_EMAIL | grep 'name: '`"
  fi

  BRAND_ID=$(echo $BRAND_ID | sed -e "s/name: //g")

  CLIENT_OUTPUT=`gcloud iap oauth-clients list $BRAND_ID`

  if [[ ! -n $CLIENT_OUTPUT ]]; then
    echo `OAuth client does not exist, creating new one...`
    CLIENT_OUTPUT=`gcloud iap oauth-clients create $BRAND_ID --display_name=$OAUTH_NAME`
  fi

  CLIENT_ID=$(echo $CLIENT_OUTPUT | sed 's/.*identityAwareProxyClients\/\([^ ]*\).*/\1/')

  CLIENT_SECRET=$(echo $CLIENT_OUTPUT | sed 's/.*secret: \([^ ]*\).*/\1/')
fi

kubectl --context=$KFCTXT -n istio-system create secret generic kubeflow-oauth --from-literal=client_id=$CLIENT_ID --from-literal=client_secret=$CLIENT_SECRET --dry-run -o yaml | kubectl apply -f -
