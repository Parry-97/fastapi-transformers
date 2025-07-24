resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "snet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = each.value.address_prefixes

  depends_on = [azurerm_virtual_network.vnet]
}
