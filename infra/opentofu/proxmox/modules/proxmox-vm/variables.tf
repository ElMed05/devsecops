variable "name" {
  description = "Name der virtuellen Maschine."
  type        = string
}

variable "node_name" {
  description = "Proxmox-Node, auf dem die VM angelegt wird."
  type        = string
}

variable "vm_id" {
  description = "Eindeutige Proxmox-VM-ID."
  type        = number
}

variable "template_vm_id" {
  description = "VM-ID des vorbereiteten Cloud-Init-Templates."
  type        = number
}

variable "template_node_name" {
  description = "Proxmox-Node, auf dem das Template liegt."
  type        = string
  default     = null
}

variable "cpu_cores" {
  description = "Anzahl virtueller CPU-Kerne."
  type        = number
}

variable "memory_mb" {
  description = "Dedizierter Arbeitsspeicher in MiB."
  type        = number
}

variable "disk_size_gb" {
  description = "Größe der Systemplatte in GiB."
  type        = number
}

variable "datastore_id" {
  description = "Proxmox-Datastore für System- und Cloud-Init-Platte."
  type        = string
}

variable "network_bridge" {
  description = "Proxmox-Netzwerk-Bridge."
  type        = string
}

variable "vlan_id" {
  description = "Optionales VLAN; null deaktiviert VLAN-Tagging."
  type        = number
  default     = null
}

variable "ipv4_address" {
  description = "Statische IPv4-Adresse in CIDR-Notation oder 'dhcp'."
  type        = string
}

variable "ipv4_gateway" {
  description = "IPv4-Standardgateway; bei DHCP null."
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "DNS-Server für Cloud-Init."
  type        = list(string)
  default     = []
}

variable "cloud_init_username" {
  description = "Initialer Benutzer des Cloud-Init-Templates."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_keys" {
  description = "Öffentliche SSH-Schlüssel für den initialen Benutzer."
  type        = list(string)
}

variable "cloud_init_user_data_file_id" {
  description = "Proxmox-Datei-ID des knotenspezifischen Cloud-Init-User-Data-Snippets."
  type        = string
}

variable "tags" {
  description = "Proxmox-Tags der VM."
  type        = list(string)
  default     = []
}

variable "qemu_guest_agent_enabled" {
  description = "Aktiviert das Warten auf den QEMU Guest Agent. Erst nach dessen Installation einschalten."
  type        = bool
  default     = false
}
