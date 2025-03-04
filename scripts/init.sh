#!/bin/bash

: "
Initialize infrastructure deployments.
Typically you only need to run this once.

Takes as inputs:
* CSP: Cloud Service Provider. E.g., azure or gcp.
* IDENTIFIER: The identifier for the CSP. E.g., the subscription id for Azure or the project id for GCP.

Example: CSP=azure IDENTIFIER=1234 bash scripts/init.sh.
"

if [ "$CSP" = "azure" ]; then
  # Login and authenticate with Azure.
  az login
  az account set --subscription "$IDENTIFIER"
elif [ "$CSP" = "gcp" ]; then
  # Login and authenticate with Google.
  gcloud auth application-default login
  gcloud config set project "$IDENTIFIER"
else
  echo "Invalid parameter. Use 'Azure' or 'GCP'."
  exit 1
fi

# Terraform initialization.
(
  cd "terraform/$CSP" || exit
  terraform init -upgrade -backend-config="backend.conf"
)
