variable "proxmox_endpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API (example: https://host:port)"
  sensitive   = true
}

variable "proxmox_api_token" {
  type        = string
  description = "The token for the Proxmox Virtual Environment API"
  sensitive   = true
}

variable "proxmox_username" {
  type        = string
  description = "The username for the Proxmox Virtual Environment API"
  sensitive   = true
}

variable "proxmox_password" {
  type        = string
  description = "The password for the Proxmox Virtual Environment API"
  sensitive   = true
}

variable "proxmox_node_name" {
  type        = string
  description = "The node name for the Proxmox Virtual Environment API"
  default     = "pve"
}

variable "proxmox_datastore_id" {
  type        = string
  description = "Datastore for VM disks"
  default     = "local-lvm"
}
