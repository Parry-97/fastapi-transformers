output "subnet_ids" {
  value       = module.app_networking.subnet_ids
  description = "Resource Ids for the deployed subnets"
}

output "rg_name" {
  value       = azurerm_resource_group.main_rg.name
  description = "Name of the resource group containing the deployed resources"
}


output "aks_name" {
  value       = module.app_backend.aks_cluster_name
  description = "Name of the deployed AKS cluster"
}
