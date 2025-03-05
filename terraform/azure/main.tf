terraform {
  required_version = ">= 1.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group_name_prefix}-${var.environment}"
  location = var.location
}

data "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault" "key_vault" {
  name                       = "${var.resource_group_name_prefix}-${var.environment}-${var.kv_suffix}"
  resource_group_name        = azurerm_resource_group.resource_group.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.kv_sku
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
}

resource "azurerm_postgresql_flexible_server" "database" {
  name                         = "${var.resource_group_name_prefix}-${var.environment}-${var.database_suffix}"
  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = var.location
  administrator_login          = var.database_administrator_login
  administrator_password       = data.azurerm_key_vault_secret.db_password.value
  sku_name                     = var.database_sku
  version                      = var.database_version
  zone                         = 2
  geo_redundant_backup_enabled = true
}

resource "azurerm_container_registry" "container_registry" {
  name                     = "${var.resource_group_name_prefix}${var.environment}${var.acr_suffix}"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  sku                      = var.acr_sku
  admin_enabled            = true
  retention_policy_in_days = 7
}

resource "azurerm_key_vault_key" "key_vault_key" {
  name         = "${var.resource_group_name_prefix}-${var.environment}-${var.kv_suffix}-${var.sa_suffix}-${var.kv_key_suffix}"
  key_vault_id = azurerm_key_vault.key_vault.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "unwrapKey", "wrapKey"]
  depends_on   = [azurerm_key_vault.key_vault]
}

# Create a Managed Identity
resource "azurerm_user_assigned_identity" "managed_identity" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  name                = "${var.resource_group_name_prefix}-${var.environment}-${var.sa_suffix}-${var.identity_suffix}"
}

resource "azurerm_key_vault_access_policy" "managed_identity_access" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.managed_identity.principal_id

  key_permissions = [
    "Get",
    "UnwrapKey",
    "WrapKey"
  ]
}

resource "azurerm_storage_account" "storage_account" {
  name                            = "${var.resource_group_name_prefix}${var.environment}${var.sa_suffix}"
  resource_group_name             = azurerm_resource_group.resource_group.name
  location                        = var.location
  account_tier                    = var.sa_account_tier
  account_replication_type        = var.sa_replication_type
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  sas_policy {
    expiration_period = "90.00:00:00"
    expiration_action = "Log"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [resource.azurerm_user_assigned_identity.managed_identity.id]
  }

  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.key_vault_key.id
    user_assigned_identity_id = azurerm_user_assigned_identity.managed_identity.id

  }

  depends_on = [azurerm_key_vault_key.key_vault_key]
}

resource "azurerm_storage_container" "storage_container" {
  for_each              = toset(var.container_names)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.storage_account.id
  container_access_type = var.container_access_type
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.resource_group_name_prefix}-${var.environment}-${var.app_service_plan_name_suffix}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  sku_name            = var.app_service_sku
  os_type             = "Linux"
}

resource "azurerm_linux_web_app" "app_service" {
  name                       = "${var.resource_group_name_prefix}-${var.environment}-${var.app_service_name_suffix}"
  resource_group_name        = azurerm_resource_group.resource_group.name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.app_service_plan.id
  client_certificate_enabled = true
  https_only                 = true

  app_settings = {
    BLOB_ACCOUNT_KEY       = azurerm_storage_account.storage_account.primary_access_key
    BLOB_ACCOUNT_NAME      = azurerm_storage_account.storage_account.name
    BLOB_CONNECTION_STRING = azurerm_storage_account.storage_account.primary_connection_string
    DB_DIALECT             = "postgresql+asyncpg"
    DB_HOST                = azurerm_postgresql_flexible_server.database.fqdn
    DB_NAME                = "postgres"
    DB_PASSWORD            = data.azurerm_key_vault_secret.db_password.value
    DB_PORT                = "5432"
    DB_USER                = var.database_administrator_login
    ENVIRONMENT            = var.environment
  }

  site_config {
    application_stack {
      docker_registry_url      = var.docker_registry_url
      docker_image_name        = var.docker_image_name
      docker_registry_username = azurerm_container_registry.container_registry.admin_username
      docker_registry_password = azurerm_container_registry.container_registry.admin_password
    }
    ftps_state                        = "FtpsOnly"
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = 5
    http2_enabled                     = true
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
  }
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${var.resource_group_name_prefix}-${var.environment}-${var.log_analytics_name_suffix}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_monitor_diagnostic_setting" "app_service_logs" {
  name                       = "${var.resource_group_name_prefix}-${var.environment}-${var.diagnostics_suffix}"
  target_resource_id         = azurerm_linux_web_app.app_service.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
