variable "acr_name" {
  description = "Name of the Azure Container Registry"
}

variable "rg_name" {
  description = "Name of the resource group"
}

variable "aks_name" {
  description = "Name of the Azure Kubernetes Service cluster"
}

variable "location" {
  description = "Name of location where to deploy the resources"
  default     = "West Europe"
}

variable "aks_node_pool_name" {
  description = "Name of the node pool to be used for the AKS cluster"
  default     = "default"
}
