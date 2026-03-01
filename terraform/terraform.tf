terraform {
  required_version = ">= 1.13.5"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.16.0"
    }
  }
}
