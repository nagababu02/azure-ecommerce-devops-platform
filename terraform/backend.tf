terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-ecommerce"
    storage_account_name = "sttfstateecommerce01"
    container_name       = "tfstate"
    key                  = "ecommerce-aks.tfstate"
  }
}
