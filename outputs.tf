
output "kube_config" {
  value = azurerm_kubernetes_cluster.cluster.kube_config_raw
  sensitive = true
}

output "public_ip_win" {
  value = azurerm_public_ip.public_ip_win.*.ip_address
}

output "public_ip_linux" {
  value = azurerm_public_ip.public_ip_linux.*.ip_address
}