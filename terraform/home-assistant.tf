locals {
  haos_config = {
    name      = "home-assistant-os"
    node_name = var.proxmox_node_name
    vm_id     = 105
    cpu       = 2
    memory    = 4096
    tags      = ["haos", "iot"]
    # HAOS requires UEFI, so we need a specific disk for EFI
    datastore_id = var.proxmox_datastore_id
    bootable = {
      filename = "haos_ova-17.0.img"
      url      = "https://github.com/home-assistant/operating-system/releases/download/17.0/haos_ova-17.0.qcow2.xz"
    }
  }
}

resource "proxmox_virtual_environment_download_file" "haos_image" {
  content_type            = "iso"
  datastore_id            = "local"
  node_name               = local.haos_config.node_name
  file_name               = local.haos_config.bootable.filename
  url                     = local.haos_config.bootable.url
  decompression_algorithm = "zst"
}

# 2. Create the HAOS VM
resource "proxmox_virtual_environment_vm" "ha_os" {
  name      = local.haos_config.name
  node_name = local.haos_config.node_name
  vm_id     = local.haos_config.vm_id
  tags      = local.haos_config.tags

  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = local.haos_config.cpu
    type  = "host"
  }

  memory {
    dedicated = local.haos_config.memory
  }

  efi_disk {
    datastore_id = local.haos_config.datastore_id
    file_format  = "raw"
    type         = "4m"
  }

  disk {
    datastore_id = local.haos_config.datastore_id
    file_id      = proxmox_virtual_environment_download_file.haos_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 32
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6+
  }
}
