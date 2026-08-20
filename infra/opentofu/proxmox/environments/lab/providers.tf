provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure

  ssh {
    username    = "root"
    private_key = file(pathexpand(var.proxmox_ssh_private_key_path))

    node {
      name    = var.proxmox_node_name
      address = var.proxmox_node_address
    }
  }

  # Das API-Token wird nicht in Git gespeichert. Der Provider liest es aus:
  # PROXMOX_VE_API_TOKEN='user@realm!token-id=token-secret'
}
