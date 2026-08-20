resource "proxmox_download_file" "ubuntu_2404_cloud_image" {
  content_type = "iso"
  datastore_id = var.image_datastore_id
  node_name    = var.proxmox_node_name
  file_name    = "ubuntu-24.04-server-cloudimg-amd64.img"
  url          = var.ubuntu_cloud_image_url

  overwrite = false
}

resource "proxmox_virtual_environment_vm" "ubuntu_2404_template" {
  name        = var.template_name
  description = "Ubuntu 24.04 Cloud-Init template; managed by OpenTofu"
  node_name   = var.proxmox_node_name
  vm_id       = var.template_vm_id
  tags        = ["template", "ubuntu-24-04", "managed-by-opentofu"]

  template = true
  started  = false
  on_boot  = false

  agent {
    # Wird nach dem ersten VM-Boot per Konfigurationsmanagement installiert.
    enabled = false
  }

  cpu {
    cores = 1
    type  = "host"
  }

  memory {
    dedicated = 1024
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = proxmox_download_file.ubuntu_2404_cloud_image.id
    interface    = "scsi0"
    size         = 8
    discard      = "on"
    ssd          = true
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = var.cloud_init_username
      keys     = var.ssh_public_keys
    }
  }

  network_device {
    bridge  = var.network_bridge
    model   = "virtio"
    vlan_id = var.vlan_id
  }

  operating_system {
    type = "l26"
  }
}
