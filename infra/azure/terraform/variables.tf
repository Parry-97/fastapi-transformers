# NOTE: We are using the recommended abbreviations for default names from
# the Microsoft Cloud Adoption Framework

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "crhftd01"
}

variable "rg_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-we-hft-d-01"
}

variable "aks_name" {
  description = "Name of the Azure Kubernetes Service cluster"
  type        = string
  default     = "aks-we-hft-d-01"
}

variable "location" {
  description = "Name of location where to deploy the resources"
  type        = string
  default     = "West Europe"
}

variable "aks_node_pool_name" {
  description = "Name of the node pool to be used for the AKS cluster"
  type        = string
  default     = "default"
}
