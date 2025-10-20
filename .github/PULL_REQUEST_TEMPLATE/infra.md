## Summary

Describe the infrastructure change and rationale.

## Components affected

- [ ] Terraform
- [ ] ArgoCD / Kustomize
- [ ] Kubernetes Manifests
- [ ] Talos
- [ ] Vault / VSO
- [ ] Storage (Longhorn / MinIO)
- [ ] Networking (Cloudflared / Tailscale)

## Risk & Rollout

- Impact:
- Rollout plan:
- Backout plan:

## Validation

- [ ] `terraform fmt` and `terraform validate`
- [ ] `terraform plan` output attached (or pasted)
- [ ] `kustomize build` and/or `kubectl diff` reviewed
- [ ] ArgoCD sync plan reviewed (no unintended drift)
- [ ] Secrets managed via Vault (no plaintext)
- [ ] Docs/README updated if needed

## Links (optional)

- Related tasks/issues/changes

