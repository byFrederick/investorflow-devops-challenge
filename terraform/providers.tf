provider "azapi" {}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
