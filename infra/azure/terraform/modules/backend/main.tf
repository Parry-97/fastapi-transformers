# Data definitions
data "azurerm_client_config" "current" {}

module "avm-res-containerregistry-registry" {
  source              = "Azure/avm-res-containerregistry-registry/azurerm"
  version             = "0.4.0"
  name                = var.acr_name
  resource_group_name = var.rg_name
  private_endpoints = {
    acr_pep_01 = {
      subnet_resource_id = var.pep_snet_id

    }
  }
  location = var.location
}


resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = var.rg_name
  dns_prefix          = var.aks_name

  default_node_pool {
    name       = var.aks_node_pool_name
    vm_size    = "Standard_B2s"
    node_count = 1
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Development"
  }
  role_based_access_control_enabled = true
}

resource "azurerm_role_assignment" "aks_acr_role_assignment" {
  principal_id                     = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = module.avm-res-containerregistry-registry.resource_id
  skip_service_principal_aad_check = true
}


resource "azurerm_role_assignment" "sp_acr_role_assignment" {
  principal_id                     = data.azurerm_client_config.current.object_id
  role_definition_name             = "AcrPush"
  scope                            = module.avm-res-containerregistry-registry.resource_id
  skip_service_principal_aad_check = true
}
