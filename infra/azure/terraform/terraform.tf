terraform {
  required_version = ">=1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.34.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Kubernetes provider configured to use AKS cluster credentials
provider "kubernetes" {
  host                   = module.app_backend.kube_config[0].host
  client_certificate     = base64decode(module.app_backend.kube_config[0].client_certificate)
  client_key             = base64decode(module.app_backend.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(module.app_backend.kube_config[0].cluster_ca_certificate)
}

# Helm provider configured to use the same Kubernetes connection
provider "helm" {
  kubernetes {
    host                   = module.app_backend.kube_config[0].host
    client_certificate     = base64decode(module.app_backend.kube_config[0].client_certificate)
    client_key             = base64decode(module.app_backend.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(module.app_backend.kube_config[0].cluster_ca_certificate)
  }
}
