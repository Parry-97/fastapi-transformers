# NOTE: We are using the recommended abbreviations for default names from
# the Microsoft Cloud Adoption Framework


variable "location" {
  description = "Name of location where to deploy the resources"
  type        = string
  default     = "West Europe"
}

variable "rg_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-we-hft-d-01"
}


