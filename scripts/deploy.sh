#!/bin/bash

: "
Use Terraform to deploy the infrastructure.

Takes as inputs:
* CSP: Cloud Service Provider. E.g., `azure` or `gcp`.
* IDENTIFIER: The identifier for the CSP. E.g., the subscription id for Azure or the project id for GCP.
* REGISTRY_NAME: The name of the container registry.
* REPOSITORY_NAME: The name of the repository.
* IMAGE_NAME: The name of the image to be built. E.g., a git hash.

Examples:
* `CSP=azure REGISTRY_NAME=myregistry REPOSITORY_NAME=myrepository IMAGE_NAME=ca20cdd bash scripts/deploy.sh`.
* `CSP=gcp IDENTIFIER=1234 REGISTRY_NAME=europe-west1 REPOSITORY_NAME=myrepository IMAGE_NAME=ca20cdd bash scripts/deploy.sh`.
"

# Stop upon error and undefined variables.
# Print commands before executing.
set -eux

# Build the UI and API (in that order).
bash scripts/build_ui.sh
CSP="$CSP" IDENTIFIER="$IDENTIFIER" REGISTRY_NAME="$REGISTRY_NAME" REPOSITORY_NAME="$REPOSITORY_NAME" IMAGE_NAME="$IMAGE_NAME" bash scripts/build_api.sh

(
  cd "terraform/$CSP" || exit
  terraform plan
  terraform apply
)
