locals {
  ssh_authorized_keys_yaml = join("\n", [
    for key in var.ssh_public_keys : "      - ${key}"
  ])

  kubernetes_cloud_init_data = <<-EOF
    #cloud-config
    users:
      - name: ${var.cloud_init_username}
        groups: [adm, sudo]
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        lock_passwd: true
        ssh_authorized_keys:
    ${local.ssh_authorized_keys_yaml}

    package_update: true
    packages:
      - qemu-guest-agent

    runcmd:
      - [systemctl, enable, --now, qemu-guest-agent]
  EOF
}

resource "proxmox_virtual_environment_file" "kubernetes_cloud_init" {
  content_type = "snippets"
  datastore_id = var.image_datastore_id
  node_name    = var.proxmox_node_name

  source_raw {
    file_name = "kubernetes-cloud-init.yaml"
    data      = local.kubernetes_cloud_init_data
  }
}
