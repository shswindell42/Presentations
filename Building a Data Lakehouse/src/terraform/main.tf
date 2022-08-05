# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "data-lakehouse-demo"
  location = "eastus2"
}

resource "azurerm_storage_account" "data_lake" {
    name = "data-lakehouse-storage"
}