variable "location" {
  description = "Name of location where to deploy the resources"
  type        = string
  default     = "West Europe"
}


variable "vnet_name" {
  description = "Name of the resource group"
  type        = string
  default     = "vnet-we-hft-d-01"
}

variable "rg_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-we-hft-d-01"
}

variable "vnet_address_space" {
  default     = ["10.0.0.0/16"]
  type        = list(string)
  description = "Address space for the Virtual Network"
}


variable "subnets" {
  default = {
    snet-we-hft-d-01 = {
      address_prefixes = ["10.0.1.0/24"]
    }
    snet-we-hft-d-02 = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
  type = map(object({
    address_prefixes = list(string)
  }))
}
