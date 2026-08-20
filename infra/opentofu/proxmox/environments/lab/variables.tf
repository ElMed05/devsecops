variable "proxmox_endpoint" {
  description = "Proxmox-API-Endpunkt, z. B. https://pve.example:8006/."
  type        = string
}

variable "proxmox_insecure" {
  description = "TLS-Prüfung abschalten. Nur für selbstsignierte Lab-Zertifikate verwenden."
  type        = bool
  default     = false
}

variable "proxmox_node_name" {
  description = "Name des Proxmox-Nodes."
  type        = string
}

variable "proxmox_node_address" {
  description = "Vom Controller erreichbare IP-Adresse des Proxmox-Nodes für SSH."
  type        = string
}

variable "proxmox_ssh_private_key_path" {
  description = "Lokaler Pfad zum privaten SSH-Schlüssel für Snippet-Uploads."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "template_vm_id" {
  description = "VM-ID eines Cloud-Init-fähigen Linux-Templates mit QEMU Guest Agent."
  type        = number
}

variable "template_name" {
  description = "Name des Ubuntu-Cloud-Init-Templates."
  type        = string
  default     = "ubuntu-2404-cloudinit-template"
}

variable "image_datastore_id" {
  description = "Datei-Datastore für das heruntergeladene Ubuntu-Cloud-Image."
  type        = string
  default     = "local"
}

variable "ubuntu_cloud_image_url" {
  description = "Offizielle Ubuntu-24.04-Cloud-Image-URL."
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"
}

variable "datastore_id" {
  description = "Datastore für VM-Platten."
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Bridge für die VM-Netzwerkkarten."
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "Optionales VLAN für alle VMs."
  type        = number
  default     = null
}

variable "ipv4_gateway" {
  description = "IPv4-Standardgateway des VM-Netzes."
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "DNS-Server der VMs."
  type        = list(string)
}

variable "cloud_init_username" {
  description = "Initialer SSH-Benutzer."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_keys" {
  description = "Öffentliche SSH-Schlüssel für alle VMs."
  type        = list(string)
}

variable "enable_platform_vm" {
  description = "Erzeugt zusätzlich die optionale GitLab/Harbor-VM."
  type        = bool
  default     = false
}

variable "kubernetes_vms" {
  description = "Definition der Kubernetes-Knoten."
  type = map(object({
    vm_id        = number
    ipv4_address = string
    cpu_cores    = number
    memory_mb    = number
    disk_size_gb = number
    role         = string
  }))

  validation {
    condition     = alltrue([for vm in values(var.kubernetes_vms) : contains(["control-plane", "worker"], vm.role)])
    error_message = "role muss 'control-plane' oder 'worker' sein."
  }
}

variable "platform_vm" {
  description = "Ressourcen der optionalen GitLab/Harbor-VM."
  type = object({
    name         = string
    vm_id        = number
    ipv4_address = string
    cpu_cores    = number
    memory_mb    = number
    disk_size_gb = number
  })
}
