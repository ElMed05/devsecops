output "kubernetes_vms" {
  description = "Erzeugte Kubernetes-VMs."
  value = {
    for name, vm in module.kubernetes_vm : name => {
      vm_id          = vm.vm_id
      ipv4_addresses = vm.ipv4_addresses
    }
  }
}

output "platform_vm" {
  description = "Optionale GitLab/Harbor-VM."
  value = var.enable_platform_vm ? {
    vm_id          = module.platform_vm[0].vm_id
    ipv4_addresses = module.platform_vm[0].ipv4_addresses
  } : null
}

output "ubuntu_template" {
  description = "Das von OpenTofu verwaltete Ubuntu-24.04-Template."
  value = {
    vm_id = proxmox_virtual_environment_vm.ubuntu_2404_template.vm_id
    name  = proxmox_virtual_environment_vm.ubuntu_2404_template.name
  }
}
