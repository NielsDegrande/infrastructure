#!/bin/bash

: "
Build the API.

Takes as inputs:
* CSP: Cloud Service Provider. E.g., azure or gcp.
* IDENTIFIER: The identifier for the CSP. E.g., the subscription id for Azure or the project id for GCP.
* REGISTRY_NAME: The name of the container registry.
* REPOSITORY_NAME: The name of the repository.
* IMAGE_NAME: The name of the image to be built. E.g., a git hash.

Examples:
* CSP=azure REGISTRY_NAME=myregistry REPOSITORY_NAME=myrepository IMAGE_NAME=ca20cdd bash scripts/build_api.sh.
* CSP=gcp IDENTIFIER=1234 REGISTRY_NAME=europe-west1 REPOSITORY_NAME=myrepository IMAGE_NAME=ca20cdd bash scripts/build_api.sh.
"

# Stop upon error and undefined variables.
# Print commands before executing.
set -eux

(
    cd api || exit
    # Build the API docker image.
    make build_base_amd
)

# Check the cloud platform and login accordingly.
if [ "$CSP" = "azure" ]; then
    az acr login --name "$REGISTRY_NAME"
    docker tag api_amd "$REGISTRY_NAME.azurecr.io/$REPOSITORY_NAME/api:$IMAGE_NAME"
    docker push "$REGISTRY_NAME.azurecr.io/$REPOSITORY_NAME/api:$IMAGE_NAME"
elif [ "$CSP" = "gcp" ]; then
    gcloud auth configure-docker "$REGISTRY_NAME-docker.pkg.dev"
    docker tag api_amd "$REGISTRY_NAME-docker.pkg.dev/$IDENTIFIER/$REPOSITORY_NAME/api:$IMAGE_NAME"
    docker push "$REGISTRY_NAME-docker.pkg.dev/$IDENTIFIER/$REPOSITORY_NAME/api:$IMAGE_NAME"
else
    echo "Invalid parameter. Use 'azure' or 'gcp'."
    exit 1
fi
