# Citadel

A self-managed homelab configuration built with Talos Linux, Kubernetes, and GitOps principles.

## Overview

Citadel is a comprehensive homelab infrastructure project that provides a modern, cloud-native environment for self-hosting applications and services. The project leverages Talos Linux as the operating system, Kubernetes for orchestration, and ArgoCD for GitOps-based application deployment.

All the commands could be found in the [Taskfile](./Taskfile.yml)

## Architecture

### Core Components

- **Talos Linux**: Immutable Linux distribution designed for Kubernetes
- **Kubernetes**: Container orchestration platform
- **ArgoCD**: GitOps continuous delivery tool
- **Terraform**: Infrastructure as Code for Proxmox VE
- **Longhorn**: Distributed storage system
- **Vault**: Secrets management
- **CouchDB**: Document database
- **Cloudflared**: Secure tunnel for external access

### Infrastructure

The infrastructure is provisioned on Proxmox VE using Terraform, creating:

- **Control Plane Node**: Talos control plane VM (2 CPU, 4GB RAM)
- **Worker Node**: Talos worker VM (2 CPU, 4GB RAM)
- **Arch Linux VM**: Additional system for specific workloads

## Prerequisites

- Proxmox VE server
- Terraform installed
- Talos CLI (`talosctl`)
- kubectl
- Task runner (for using Taskfile)

## Quick Start

### 1. Infrastructure Setup

Configure your Proxmox credentials and deploy the infrastructure:

```bash
# Set up Terraform variables (we can directly modified the taskfile)
export TF_VAR_proxmox_endpoint="https://your-proxmox-server:8006"
export TF_VAR_proxmox_api_token="your-api-token"
export TF_VAR_proxmox_username="your-username"
export TF_VAR_proxmox_password="your-password"

# Deploy infrastructure
task setup-talos-node
```

### 2. Talos Cluster Configuration

Generate and apply Talos configuration:

```bash
# Generate Talos configuration
task gen-talos-config

# Bootstrap the cluster
task bootstrap-talos

# Get kubeconfig
task add-talos-kubeinfo
```

### 3. ArgoCD Setup

Install and configure ArgoCD:

```bash
# Install ArgoCD
task setup-argocd

# Get ArgoCD admin password
task get-argocd-password

# Port forward to access ArgoCD UI
task port-forward-argocd
```

Access ArgoCD at `https://localhost:8080` (admin password from previous step).

## Project Structure

```
citadel/
├── argocd/                    # ArgoCD applications
│   ├── app-of-apps.yaml      # Root application
│   └── apps/                 # Application definitions
│       ├── argocd/           # ArgoCD configuration
│       ├── vault/            # Vault secrets management
│       ├── longhorn/         # Distributed storage
│       ├── couchdb/          # Document database
│       └── cloudflared/      # Secure tunnels
├── terraform/                # Infrastructure as Code
│   ├── talos.tf             # Talos VMs
│   ├── arch.tf              # Arch Linux VM
│   └── variables.tf         # Terraform variables
├── talos/                    # Talos-specific configurations
├── _out/                     # Generated configurations
└── Taskfile.yml             # Task automation
```

## Applications

### ArgoCD
GitOps continuous delivery tool for managing Kubernetes applications.

### Vault
HashiCorp Vault for secrets management and encryption.

### Longhorn
Distributed block storage for Kubernetes, providing persistent volumes.

### CouchDB
Document-oriented database for application data storage.

### Cloudflared
Secure tunnel service for external access to internal services.

## Task Automation

The project includes a Taskfile with common operations:

- `task check-talos-node`: Validate Terraform configuration
- `task setup-talos-node`: Deploy infrastructure
- `task gen-talos-config`: Generate Talos configuration
- `task bootstrap-talos`: Bootstrap Kubernetes cluster
- `task setup-argocd`: Install ArgoCD
- `task get-argocd-password`: Retrieve ArgoCD admin password
- `task port-forward-argocd`: Access ArgoCD UI locally

## Configuration

### Environment Variables

Set the following environment variables for Talos configuration:

- `CONTROL_PLANE_IP`: IP address of the control plane node
- `WORKER_IP`: IP address of the worker node
- `TALOS_VERSION`: Talos version (default: v1.11.1)

### Terraform Variables

To use terraform variables we can create `.auto.tfvars` file and fill the following information:

- `proxmox_endpoint`: Proxmox API endpoint
- `proxmox_api_token`: API token for authentication
- `proxmox_username`: Proxmox username
- `proxmox_password`: Proxmox password
- `proxmox_node_name`: Target Proxmox node (default: "pve")
- `proxmox_datastore_id`: Storage datastore (default: "local-lvm")

## Security Considerations

- All VMs use DHCP for network configuration
- Talos provides immutable, secure Linux distribution
- Vault integration for secrets management
- Cloudflared provides secure external access

## Troubleshooting

### Common Issues

1. **Terraform apply fails**: Check Proxmox credentials and network connectivity
2. **Talos bootstrap fails**: Ensure nodes are healthy and accessible
3. **ArgoCD sync issues**: Check application configurations and repository access

### Useful Commands

```bash
# Check Talos node status
talosctl --talosconfig _out/talosconfig get nodes

# View Kubernetes nodes
kubectl get nodes

# Check ArgoCD applications
kubectl get applications -n argocd
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the terms specified in the LICENSE file.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Talos documentation
3. Check ArgoCD documentation
4. Open an issue in this repository
