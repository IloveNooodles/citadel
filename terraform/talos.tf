resource "proxmox_virtual_environment_download_file" "talos_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node_name

  url = "https://factory.talos.dev/image/6d1f5bd37d6a6bf937ad651c5482d93571942c19bb32dde87b6a17b5e443ec39/v1.11.1/metal-amd64.iso"
}

resource "proxmox_virtual_environment_vm" "talos_template" {
  name      = "talos-template"
  node_name = var.proxmox_node_name
  tags      = ["terraform", "talos", "template"]

  template = true
  started  = false

  bios        = "seabios"
  description = "Managed by Terraform"

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
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

locals {
  nodes = {
    "talos-control-plane" = {
      "node_name" = var.proxmox_node_name
      "vm_id"     = 102
      "cpu"       = 2
      "tags"      = ["kubernetes", "control-plane"]
    }
    "talos-worker-0" = {
      "node_name" = var.proxmox_node_name
      "vm_id"     = 103
      "cpu"       = 2
      "tags"      = ["kubernetes", "worker"]
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos" {
  for_each = local.nodes
  tags     = each.value.tags

  name      = each.key
  node_name = each.value.node_name
  vm_id     = each.value.vm_id

  clone {
    vm_id = proxmox_virtual_environment_vm.talos_template.id
  }

  agent {
    # NOTE: The agent is installed and enabled as part of the cloud-init configuration in the template VM, see cloud-config.tf
    # The working agent is *required* to retrieve the VM IP addresses.
    # If you are using a different cloud-init configuration, or a different clone source
    # that does not have the qemu-guest-agent installed, you may need to disable the `agent` below and remove the `vm_ipv4_address` output.
    # See https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#qemu-guest-agent for more details.
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "x86-64-v2-AES"
  }
}
