output "jenkins_vm_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "jenkins_ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.public_ip.ip_address}"
}

output "sonarqube_vm_ip" {
  value = azurerm_public_ip.sonarqube_ip.ip_address
}

output "sonarqube_ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.sonarqube_ip.ip_address}"
}

output "docker_vm_ip" {
  value = azurerm_public_ip.docker_ip.ip_address
}

output "docker_ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.docker_ip.ip_address}"
}

