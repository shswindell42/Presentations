# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
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

  tags = local.tags
}


