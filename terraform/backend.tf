terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-stuff"
    storage_account_name = "myiacstates"
    container_name       = "tfstate"
    key = "legacyapp.terraform.tfstate"
  }
}
