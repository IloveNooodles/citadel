output "vm_ipv4_address" {
  description = "The IPv4 address of the VMs"
  value = {
    for key, val in proxmox_virtual_environment_vm.talos :
    key => val.ipv4_addresses
  }

}
