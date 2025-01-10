# Infrastructure

## Introduction

This repository holds infrastructure as code.
Terraform is used to provision the infrastructure.

## Getting Started

### Prerequisites

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

You need to install the CLI tool for the cloud provider you are using:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)

### Installation

```shell
python3 -m venv venv
source venv/bin/activate
make install_dev
```

If you want to commit changes to `scripts`,
you need to install ShellCheck, e.g. with:

```shell
brew install shellcheck
```

### Create a backend

This is a one-time setup. It is not part of this infra-as-code.
Populate the `backend.conf` with the required values.

#### Azure

Create a storage account and a container to store the Terraform state.
NOTE: It might be required to add the `object_id` of the principal running `terraform apply` to the key vault with Get key permissions.

##### First-Time Setup

A first deploy will typically fail because the Key Vault is not yet populated with the required secrets.

One can deploy the Key Vault separately:

```shell
terraform apply -target=azurerm_key_vault.key_vault
```

Then manually add the "db-password" secret in the Key Vault. Then run `terraform apply` again to finish the deployment.

#### GCP

Create a bucket to store the Terraform state.

## Infrastructure Setup

Initialize (one-time setup) with

```shell
# NOTE: Populate the variables.
CSP= IDENTIFIER= bash scripts/init.sh`.
```

For local use, you can create symbolic links to the API and UI repository.

```shell
ln -s {absolute_path_to_api_repo} api
ln -s {absolute_path_to_ui_repo} ui
```

Then use the deploy script to build and deploy the infrastructure:

```shell
# NOTE: Populate the variables.
CSP= IDENTIFIER= REGISTRY_NAME= REPOSITORY_NAME= bash scripts/deploy.sh
```

## Post-Deployment Setup

1. Run `alembic upgrade head` against the database.
1. Populate with any data required. E.g., follow the instructions in the API repository.

## Multi-Environment Setup

- Create a separate backend, e.g., `backend.conf`, for each environment.
- Create a separate `terraform.tfvars` for each environment.
- Use the `-backend-config` flag with `terraform init` to specify the backend configuration file.
- Use the `-var-file` flag with `terraform plan` and `terraform apply` to specify the variables file.
