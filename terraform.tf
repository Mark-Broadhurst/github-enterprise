terraform {
  required_version = ">= 1.9.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  backend "azurerm" {
    subscription_id      = "00000000-0000-0000-0000-000000000000"
    resource_group_name  = "example-rg"
    storage_account_name = "examplestorageaccount"
    container_name       = "github-enterprise"
    key                  = "terraform.tfstate"
  }
}

provider "github" {
  owner = "MyOrganization"
  app_auth {
    id              = var.app_id
    installation_id = var.app_installation_id
    pem_file        = file("app.pem")
  }
}