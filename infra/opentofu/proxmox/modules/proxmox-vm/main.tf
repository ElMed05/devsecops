resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vm_id
  tags      = sort(distinct(concat(["managed-by-opentofu"], var.tags)))

  clone {
    vm_id     = var.template_vm_id
    node_name = var.template_node_name
    full      = true
    retries   = 3
  }

  agent {
    enabled = var.qemu_guest_agent_enabled
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size_gb
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge  = var.network_bridge
    model   = "virtio"
    vlan_id = var.vlan_id
  }

  initialization {
    datastore_id      = var.datastore_id
    user_data_file_id = var.cloud_init_user_data_file_id

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }

  }

  operating_system {
    type = "l26"
  }

  on_boot = true
  started = true
}
