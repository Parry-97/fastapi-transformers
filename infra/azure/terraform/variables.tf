# NOTE: We are using the recommended abbreviations for names from
# the Microsoft Cloud Adoption Framework

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  default     = "crhftd01"
}

variable "rg_name" {
  description = "Name of the resource group"
  default     = "rg-we-hft-d-01"
}

variable "aks_name" {
  description = "Name of the Azure Kubernetes Service cluster"
  default     = "aks-we-hft-d-01"
}

variable "location" {
  description = "Name of location where to deploy the resources"
  default     = "West Europe"
}

variable "aks_node_pool_name" {
  description = "Name of the node pool to be used for the AKS cluster"
  default     = "default"
}
