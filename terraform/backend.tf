terraform {
  backend "azurerm" {
    resource_group_name  = "rg-investorflow-terraform-state"
    storage_account_name = "investorflowtfstate"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}
