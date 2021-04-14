#!/bin/bash
#
# A simple bash script to check that when using CloudEnpoints
# to create an endpoint we don't endup with a domain
# that exceeds the maximum allowed length of 62 characters.
# The domain will be ${NAME}.endpoints.${PROJECT}.cloud.goog\
#
# Run this as  PROJECT=${PROJECT} NAME=${NAME} ./check_domain_length
domain=${NAME}.endpoints.${PROJECT}.cloud.goog

if [ ${#domain} -gt 62 ]; then
  echo The ${domain} exceeds is ${#domain} characters long which exceeds the maximum length of 62 characters
  echo choose a shorter name for your deployment
  exit 1
fi