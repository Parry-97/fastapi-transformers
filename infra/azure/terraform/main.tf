# Resource definitions
resource "azurerm_resource_group" "main_rg" {
  name     = var.rg_name
  location = var.location
}

module "app_backend" {
  source = "./modules/backend"
  providers = {
    azurerm = azurerm
  }
  pep_snet_id = module.app_networking.subnet_ids[1]
  rg_name     = azurerm_resource_group.main_rg.name
  location    = var.location
}


module "app_networking" {
  source = "./modules/networking"
  providers = {
    azurerm = azurerm
  }
  rg_name  = azurerm_resource_group.main_rg.name
  location = var.location
}

# KubeRay operator Helm release
# This resource depends on the AKS cluster being created first
resource "helm_release" "kuberay_operator" {
  name             = "kuberay-operator"
  repository       = "https://ray-project.github.io/kuberay-helm/"
  chart            = "kuberay-operator"
  version          = "1.1.1" # Pinning version for stability
  namespace        = "kuberay-system"
  create_namespace = true

  depends_on = [module.app_backend]
}
