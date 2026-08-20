module "kubernetes_vm" {
  for_each = var.kubernetes_vms

  source = "../../modules/proxmox-vm"

  depends_on = [proxmox_virtual_environment_vm.ubuntu_2404_template]

  name                         = each.key
  node_name                    = var.proxmox_node_name
  vm_id                        = each.value.vm_id
  template_vm_id               = var.template_vm_id
  template_node_name           = var.proxmox_node_name
  cpu_cores                    = each.value.cpu_cores
  memory_mb                    = each.value.memory_mb
  disk_size_gb                 = each.value.disk_size_gb
  datastore_id                 = var.datastore_id
  network_bridge               = var.network_bridge
  vlan_id                      = var.vlan_id
  ipv4_address                 = each.value.ipv4_address
  ipv4_gateway                 = var.ipv4_gateway
  dns_servers                  = var.dns_servers
  cloud_init_username          = var.cloud_init_username
  ssh_public_keys              = var.ssh_public_keys
  cloud_init_user_data_file_id = proxmox_virtual_environment_file.kubernetes_cloud_init.id
  tags                         = ["kubernetes", each.value.role, "lab"]
  qemu_guest_agent_enabled     = true
}

module "platform_vm" {
  count = var.enable_platform_vm ? 1 : 0

  source = "../../modules/proxmox-vm"

  depends_on = [proxmox_virtual_environment_vm.ubuntu_2404_template]

  name                         = var.platform_vm.name
  node_name                    = var.proxmox_node_name
  vm_id                        = var.platform_vm.vm_id
  template_vm_id               = var.template_vm_id
  template_node_name           = var.proxmox_node_name
  cpu_cores                    = var.platform_vm.cpu_cores
  memory_mb                    = var.platform_vm.memory_mb
  disk_size_gb                 = var.platform_vm.disk_size_gb
  datastore_id                 = var.datastore_id
  network_bridge               = var.network_bridge
  vlan_id                      = var.vlan_id
  ipv4_address                 = var.platform_vm.ipv4_address
  ipv4_gateway                 = var.ipv4_gateway
  dns_servers                  = var.dns_servers
  cloud_init_username          = var.cloud_init_username
  ssh_public_keys              = var.ssh_public_keys
  cloud_init_user_data_file_id = proxmox_virtual_environment_file.kubernetes_cloud_init.id
  tags                         = ["platform", "gitlab", "harbor", "lab"]
  qemu_guest_agent_enabled     = true
}
