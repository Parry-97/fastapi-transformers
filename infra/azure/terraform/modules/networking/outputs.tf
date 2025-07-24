output "subnet_ids" {
  value      = tolist([for snet in azurerm_subnet.snet : snet.id])
  depends_on = [azurerm_subnet.snet]
}
