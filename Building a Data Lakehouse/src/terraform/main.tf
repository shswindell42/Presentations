# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.23.0"
    }
  }

  required_version = ">= 1.1.0"

  backend "azurerm" {
    resource_group_name = "terraform"   
    storage_account_name = "soundbiterraform"
    container_name = "tfstate"
    key = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "data-lakehouse-demo"
  location = "eastus2"
}

locals {
  tags = {
    presentation = "Building a Data Lakehouse"
  }
}

variable "sql_password" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "aad_admin_object_id" {
  type = string
}

resource "azurerm_storage_account" "data_lake" {
  name = "sbilakehousestorage"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"

  is_hns_enabled = true

  tags = local.tags
}

resource "azurerm_role_assignment" "data_lake_access" {
  scope = azurerm_storage_account.data_lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id = var.aad_admin_object_id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "primaryfs" {
  name = "data"
  storage_account_id = azurerm_storage_account.data_lake.id
}

resource "azurerm_synapse_workspace" "main" {
  name = "sbi-synapse-demo"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.primaryfs.id

  sql_administrator_login = "sqladminuser"
  sql_administrator_login_password = var.sql_password

  aad_admin {
    login = "AzureAD Admin"
    object_id = var.aad_admin_object_id
    tenant_id = var.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }

  github_repo {
    account_name = "shswindell42"
    branch_name = "main"
    repository_name = "Presentations"
    root_folder = "/Building a Data Lakehouse/src/synapse"
  }

  lifecycle {
    ignore_changes = [
      github_repo[0].last_commit_id
    ]
  }

  tags = local.tags
}

resource "azurerm_synapse_firewall_rule" "azure_access" {
  name = "AllowAllWindowsAzureIps"
  start_ip_address = "0.0.0.0"
  end_ip_address = "0.0.0.0"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
}

resource "azurerm_synapse_firewall_rule" "all_access" {
  name = "AllowAll"
  start_ip_address = "0.0.0.0"
  end_ip_address = "255.255.255.255"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
} 

resource "azurerm_synapse_role_assignment" "example" {
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  role_name            = "Synapse SQL Administrator"
  principal_id         = var.aad_admin_object_id
  depends_on = [
    azurerm_synapse_firewall_rule.all_access
  ]
}

resource "azurerm_role_assignment" "synapse_data_lake_access" {
  scope = azurerm_storage_account.data_lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id = azurerm_synapse_workspace.main.identity[0].principal_id
}

resource "azurerm_synapse_spark_pool" "spark" {
  name                 = "sbisparkdemo"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  cache_size           = 100
  spark_version = "3.2"

  auto_scale {
    max_node_count = 10
    min_node_count = 3
  }

  auto_pause {
    delay_in_minutes = 15
  }
}