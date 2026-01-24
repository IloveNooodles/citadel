locals {
  configuration = {
    "omarchy" = {
      "name"              = "gawrgare-omarchy"
      "node_name"         = var.proxmox_node_name
      "vm_id"             = 101
      "cpu"               = 2
      "tags"              = ["arch", "omarchy"]
      "memory"            = 4096
      "installation_disk" = 10
      "data_disk"         = 50
    }
    "bootable" = {
      type      = "iso"
      file_name = "omarchy-3.0.1.iso"
      url       = "https://iso.omarchy.org/omarchy-3.0.1.iso"
    }
  }
}

resource "proxmox_virtual_environment_download_file" "omarchy_image" {
  content_type = local.configuration.bootable.type
  datastore_id = "local"
  node_name    = local.configuration.omarchy.node_name
  file_name    = local.configuration.bootable.file_name

  url = local.configuration.bootable.url
}

resource "proxmox_virtual_environment_vm" "omarchy" {
  tags = local.configuration.omarchy.tags

  name        = local.configuration.omarchy.name
  node_name   = local.configuration.omarchy.node_name
  vm_id       = local.configuration.omarchy.vm_id
  bios        = "seabios"
  description = "Managed by Terraform"
  on_boot     = true

  agent {
    enabled = false
  }

  cpu {
    cores = local.configuration.omarchy.cpu
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = local.configuration.omarchy.memory
  }

  # Installation disk
  disk {
    datastore_id = var.proxmox_datastore_id
    file_id      = proxmox_virtual_environment_download_file.omarchy_image.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = local.configuration.omarchy.installation_disk
  }

  # Datadisk
  disk {
    datastore_id = var.proxmox_datastore_id
    interface    = "scsi1"
    iothread     = true
    discard      = "on"
    size         = local.configuration.omarchy.data_disk
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  operating_system {
    type = "l26"
  }

  network_device {
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = all
  }
}
