# Citadel

A self-managed homelab configuration built with Talos Linux, Kubernetes, and GitOps principles.

## Overview

Citadel is a homelab infrastructure project for self-hosting applications with Talos Linux, Kubernetes, and ArgoCD.

Common infrastructure commands are defined in the [Taskfile](./Taskfile.yml). Kubernetes applications are managed from `argocd/`.

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
# Set Proxmox Terraform variables for this shell session
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

# Register the GitOps root application
kubectl apply -f argocd/app-of-apps.yaml

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
│   └── apps/                 # Application definitions and values
├── terraform/                # Infrastructure as Code
│   ├── talos.tf             # Talos VMs
│   ├── arch.tf              # Arch Linux VM
│   ├── home-assistant.tf    # Home Assistant VM
│   └── variables.tf         # Terraform variables
├── talos/                    # Talos machine patches
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

### Cluster services

Cilium provides Kubernetes networking. Longhorn provides persistent storage. Vault and Vault Secrets Operator handle secrets. Prometheus and Grafana provide monitoring. RustFS provides S3-compatible storage. Tailscale provides private access.

### Other workloads

CouchDB and the Arch Linux and Home Assistant VMs provide application and homelab workloads.

### Zot

Optional self-hosted OCI registry backed by the `zot` bucket in RustFS. Zot is paused with `replicaCount: 0` while GHCR is in use; its RustFS data and persistent volume are retained. To resume it, set `replicaCount: 1` in `argocd/apps/zot/zot.yaml` and push the change for ArgoCD to sync.

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

### Talos Configuration

The current control-plane and worker addresses, Talos version, and installer schema are set in the `gen-talos-config` task in `Taskfile.yml`. Update those values there when the cluster configuration changes. That task generates the machine configs and applies them to both nodes.

### Terraform Variables

Provide these required Terraform variables with `TF_VAR_*` environment variables (as shown above) or a local Terraform variables file:

- `proxmox_endpoint`: Proxmox API endpoint
- `proxmox_api_token`: API token for authentication
- `proxmox_username`: Proxmox username
- `proxmox_password`: Proxmox password
- `proxmox_node_name`: Target Proxmox node (default: "pve")
- `proxmox_datastore_id`: Storage datastore (default: "local-lvm")

`task add-talos-kubeinfo` writes the cluster kubeconfig to `~/.kube/talos-kubeconfig.yml`; select it with `kubectl --kubeconfig ~/.kube/talos-kubeconfig.yml` or merge it into your usual kubeconfig.

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
