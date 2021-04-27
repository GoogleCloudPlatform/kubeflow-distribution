#!/bin/bash
#
# Check if CLIENT_ID and CLIENT_SECRET are set

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
   echo "Error: Environment variables CLIENT_ID and CLIENT_SECRET must be set to the OAuth client id and secret to be used with IAP"
   exit 1
fi	