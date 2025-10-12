locals {
  nodes = {
    "talos-control-plane" = {
      "node_name" = var.proxmox_node_name
      "vm_id"     = 110
      "cpu"       = 2
      "tags"      = ["kubernetes", "control-plane"]
      "memory"    = 6144
    }
    "talos-worker-0" = {
      "node_name" = var.proxmox_node_name
      "vm_id"     = 111
      "cpu"       = 2
      "tags"      = ["kubernetes", "worker"]
      "memory"    = 6144
    }
  }

  bootable = {
    type      = "iso"
    file_name = "talos-v1.11.1.iso"
    url       = "https://factory.talos.dev/image/b1ba84be4f5193a24085cc7e22fce31105e1583504d7d5aef494318f7cb1abd0/v1.11.1/metal-amd64.iso"
  }
}

resource "proxmox_virtual_environment_download_file" "talos_image" {
  content_type = local.bootable.type
  datastore_id = "local"
  node_name    = var.proxmox_node_name
  file_name    = local.bootable.file_name

  url = local.bootable.url
}

resource "proxmox_virtual_environment_vm" "talos" {
  for_each = local.nodes
  tags     = each.value.tags

  name        = each.key
  node_name   = each.value.node_name
  vm_id       = each.value.vm_id
  bios        = "seabios"
  description = "Managed by Terraform"
  started     = false
  template    = false

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.proxmox_datastore_id
    file_id      = proxmox_virtual_environment_download_file.talos_image.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 100
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}
