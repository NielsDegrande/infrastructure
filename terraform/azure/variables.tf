# General.

variable "location" {
  type        = string
  description = "The Azure Region in which the resources will be deployed."
}

variable "environment" {
  type        = string
  description = "The environment in which the resources will be created."
  default     = "dev"
}

# Resource Group.

variable "resource_group_name_prefix" {
  type        = string
  description = "The name of the resource group in which to create the resources."
}

# Database.

variable "database_suffix" {
  type        = string
  description = "The suffix to append to the database name."
  default     = "db"
}

variable "database_administrator_login" {
  type        = string
  description = "The administrator login for the database."
  default     = "postgres"
}

variable "database_sku" {
  type        = string
  description = "SKU tier for the database."
  default     = "GP_Standard_D2ds_v5"
}

variable "database_version" {
  type        = string
  description = "Database version."
  default     = "16"
}

# Container Registry.

variable "acr_suffix" {
  type        = string
  description = "The suffix to append to the acr name."
  default     = "acr"
}

variable "acr_sku" {
  type        = string
  description = "SKU for the ACR."
  # Standard not Basic to allow for vulnerability scanning.
  default = "Standard"
}

# Storage Account.

variable "sa_suffix" {
  type        = string
  description = "The suffix to append to the storage account name."
  default     = "sa"
}

variable "sa_account_tier" {
  type        = string
  description = "The storage account tier."
  default     = "Standard"
}

variable "sa_replication_type" {
  type        = string
  description = "The storage account replication type."
  default     = "GRS"
}

variable "container_names" {
  type = list(string)
  default = [
    "raw",
  ]
}

variable "container_access_type" {
  type        = string
  description = "The access type for the storage container."
  default     = "private"
}

# Key vault.

variable "kv_suffix" {
  type        = string
  description = "The suffix to append to the key vault name."
  default     = "kv"
}

variable "kv_sku" {
  type        = string
  description = "SKU for the Key Vault."
  default     = "standard"
}

variable "kv_key_suffix" {
  type        = string
  description = "The suffix to append to the key vault key name."
  default     = "key"
}

# Managed Identity.

variable "identity_suffix" {
  type        = string
  description = "The suffix to append to the managed identity name."
  default     = "identity"
}

# App Service.

variable "app_service_plan_name_suffix" {
  description = "The name of the App Service Plan."
  default     = "appservice-plan"
}

variable "app_service_name_suffix" {
  description = "The name of the App Service."
  default     = "appservice"
}

variable "log_analytics_name_suffix" {
  description = "The name of the Log Analytics Workspace."
  default     = "loganalyticsworkspace"
}

variable "diagnostics_suffix" {
  description = "The suffix to append to the diagnostics settings name."
  default     = "diagnostics"
}

variable "app_service_sku" {
  description = "The SKU of the App Service."
  default     = "P1v3"
}

variable "docker_registry_url" {
  description = "The Docker registry URL."
}

variable "docker_image_name" {
  description = "The Docker image to deploy."
}

variable "health_check_path" {
  description = "The health check path for the App Service."
  default     = "/api/docs"
}
