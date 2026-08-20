output "vm_id" {
  description = "Proxmox-VM-ID."
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "Name der VM."
  value       = proxmox_virtual_environment_vm.this.name
}

output "ipv4_addresses" {
  description = "Vom QEMU Guest Agent gemeldete IPv4-Adressen."
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}
