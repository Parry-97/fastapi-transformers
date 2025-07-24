# Resource definitions
resource "azurerm_resource_group" "main_rg" {
  name     = var.rg_name
  location = var.location
}

module "app_backend" {
  source = "./modules/backend"
}


module "app_networking" {
  source = "./modules/networking"
}
