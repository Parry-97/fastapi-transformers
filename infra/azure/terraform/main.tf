# Resource definitions
resource "azurerm_resource_group" "main_rg" {
  name     = var.rg_name
  location = var.location
}

module "app_backend" {
  source = "./modules/backend"
  providers = {
    azurerm = azurerm.azure
  }
  pep_snet_id = module.app_networking.subnet_ids[1]
  rg_name     = azurerm_resource_group.main_rg.name
}


module "app_networking" {
  source = "./modules/networking"
  providers = {
    azurerm = azurerm.azure
  }
  rg_name = azurerm_resource_group.main_rg.name
}
