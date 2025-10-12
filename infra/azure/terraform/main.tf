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
}


module "app_networking" {
  source = "./modules/networking"
  providers = {
    azurerm = azurerm
  }
  rg_name = azurerm_resource_group.main_rg.name
}

# Helm provider configuration for Kubernetes
provider "helm" {
  kubernetes {
    host                   = module.app_backend.kube_config[0].host
    client_certificate     = base64decode(module.app_backend.kube_config[0].client_certificate)
    client_key             = base64decode(module.app_backend.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(module.app_backend.kube_config[0].cluster_ca_certificate)
  }
}

# KubeRay operator Helm release
resource "helm_release" "kuberay_operator" {
  name             = "kuberay-operator"
  repository       = "https://ray-project.github.io/kuberay-helm/"
  chart            = "kuberay-operator"
  version          = "1.1.1" # Pinning version for stability
  namespace        = "ray-systems"
  create_namespace = true
}
