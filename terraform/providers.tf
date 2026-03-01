provider "azapi" {}

provider "azuread" {}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
