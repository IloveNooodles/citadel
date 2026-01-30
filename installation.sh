#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TERRAFORM_DIR="$REPO_ROOT_DIR/terraform"
OUT_DIR="$REPO_ROOT_DIR/_out"

log() {
  echo "[installation] $*"
}

die() {
  echo "[installation][error] $*" >&2
  exit 1
}

require_bin() {
  local bin="$1"
  command -v "$bin" >/dev/null 2>&1 || die "Required binary '$bin' not found in PATH"
}

preflight_checks() {
  log "Running preflight checks"
  require_bin terraform
  require_bin jq
  require_bin ssh
  require_bin kubectl
  require_bin talosctl
}

prompt_inputs() {
  log "Collecting inputs"
  read -r -p "Enter your username (used for homelab name): " USERNAME_INPUT
  if [[ -z "${USERNAME_INPUT:-}" ]]; then
    die "Username is required"
  fi
  HOMELAB_NAME="${USERNAME_INPUT}-homelab"

  echo
  log "Proxmox API credentials (for Terraform)"
  read -r -p "Proxmox endpoint (e.g., https://your-proxmox:8006): " PROXMOX_ENDPOINT
  read -r -p "Proxmox API token: " PROXMOX_API_TOKEN
  read -r -p "Proxmox username: " PROXMOX_USERNAME
  read -r -s -p "Proxmox password: " PROXMOX_PASSWORD; echo
  read -r -p "Proxmox node name [pve]: " PROXMOX_NODE_NAME; PROXMOX_NODE_NAME="${PROXMOX_NODE_NAME:-pve}"
  read -r -p "Proxmox datastore id [local-lvm]: " PROXMOX_DATASTORE_ID; PROXMOX_DATASTORE_ID="${PROXMOX_DATASTORE_ID:-local-lvm}"

  echo
  log "Proxmox SSH details (to start/rename VMs)"
  read -r -p "Proxmox SSH host (IP or hostname): " PROXMOX_SSH_HOST
  read -r -p "Proxmox SSH user [root]: " PROXMOX_SSH_USER; PROXMOX_SSH_USER="${PROXMOX_SSH_USER:-root}"
  read -r -p "Use SSH key or password? [key/password] [key]: " SSH_AUTH_MODE; SSH_AUTH_MODE="${SSH_AUTH_MODE:-key}"
  if [[ "$SSH_AUTH_MODE" == "key" ]]; then
    read -r -p "Path to SSH private key [~/.ssh/id_rsa]: " PROXMOX_SSH_KEY; PROXMOX_SSH_KEY="${PROXMOX_SSH_KEY:-~/.ssh/id_rsa}"
    PROXMOX_SSH_KEY="${PROXMOX_SSH_KEY/#\~/$HOME}"
    [[ -f "$PROXMOX_SSH_KEY" ]] || die "SSH key not found at $PROXMOX_SSH_KEY"
  else
    read -r -s -p "Proxmox SSH password: " PROXMOX_SSH_PASSWORD; echo
    if ! command -v sshpass >/dev/null 2>&1; then
      die "sshpass is required for password auth. Please install sshpass or use SSH key mode."
    fi
  fi

  echo
  log "Talos settings (press Enter for defaults)"
  read -r -p "Talos version [v1.11.1]: " TALOS_VERSION; TALOS_VERSION="${TALOS_VERSION:-v1.11.1}"
  read -r -p "Talos installer schema [b1ba84be4f5193a24085cc7e22fce31105e1583504d7d5aef494318f7cb1abd0]: " TALOS_SCHEMA; TALOS_SCHEMA="${TALOS_SCHEMA:-b1ba84be4f5193a24085cc7e22fce31105e1583504d7d5aef494318f7cb1abd0}"
}

write_tfvars() {
  log "Writing terraform.auto.tfvars (contains secrets)"
  mkdir -p "$TERRAFORM_DIR"
  cat >"$TERRAFORM_DIR/terraform.auto.tfvars" <<EOF
proxmox_endpoint    = "${PROXMOX_ENDPOINT}"
proxmox_api_token   = "${PROXMOX_API_TOKEN}"
proxmox_username    = "${PROXMOX_USERNAME}"
proxmox_password    = "${PROXMOX_PASSWORD}"
proxmox_node_name   = "${PROXMOX_NODE_NAME}"
proxmox_datastore_id = "${PROXMOX_DATASTORE_ID}"
EOF
  chmod 600 "$TERRAFORM_DIR/terraform.auto.tfvars"
}

ssh_cmd() {
  if [[ "$SSH_AUTH_MODE" == "key" ]]; then
    ssh -i "$PROXMOX_SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${PROXMOX_SSH_USER}@${PROXMOX_SSH_HOST}" "$@"
  else
    sshpass -p "$PROXMOX_SSH_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${PROXMOX_SSH_USER}@${PROXMOX_SSH_HOST}" "$@"
  fi
}

terraform_apply() {
  log "Running terraform init & apply"
  (cd "$TERRAFORM_DIR" && terraform init -input=false && terraform apply -auto-approve -input=false)
}

start_vms() {
  log "Starting VMs in Proxmox via SSH (qm start 110, 111, 101)"
  ssh_cmd "qm start 110 || true"
  ssh_cmd "qm start 111 || true"
  ssh_cmd "qm start 101 || true"
}

refresh_state() {
  (cd "$TERRAFORM_DIR" && terraform apply -refresh-only -auto-approve -input=false >/dev/null 2>&1 || true)
}

poll_ips() {
  log "Waiting for Talos VM IPs to be reported by Terraform"
  local attempts=60
  local sleep_sec=20
  CONTROL_PLANE_IP=""
  WORKER_IP=""
  for ((i=1;i<=attempts;i++)); do
    refresh_state
    local IPS_JSON
    if ! IPS_JSON=$(terraform -chdir="$TERRAFORM_DIR" output -json vm_ipv4_address 2>/dev/null); then
      log "terraform output not ready yet (attempt ${i}/${attempts})"
      sleep "$sleep_sec"
      continue
    fi
    local CP_RAW
    local WK_RAW
    CP_RAW=$(jq -r '.value["talos-control-plane"][0] // empty' <<<"$IPS_JSON" || true)
    WK_RAW=$(jq -r '.value["talos-worker-0"][0] // empty' <<<"$IPS_JSON" || true)
    if [[ -n "$CP_RAW" && -n "$WK_RAW" && "$CP_RAW" != "null" && "$WK_RAW" != "null" ]]; then
      CONTROL_PLANE_IP="${CP_RAW%%/*}"
      WORKER_IP="${WK_RAW%%/*}"
      if [[ -n "$CONTROL_PLANE_IP" && -n "$WORKER_IP" ]]; then
        log "Got IPs: control-plane=${CONTROL_PLANE_IP}, worker=${WORKER_IP}"
        return 0
      fi
    fi
    log "IPs not available yet, retrying in ${sleep_sec}s (${i}/${attempts})"
    sleep "$sleep_sec"
  done
  die "Timed out waiting for VM IPs from Terraform"
}

talos_setup() {
  log "Generating Talos configs for ${HOMELAB_NAME}"
  mkdir -p "$OUT_DIR"
  TALOSCONFIG="$OUT_DIR/talosconfig"
  export TALOSCONFIG
  talosctl gen config "${HOMELAB_NAME}" "https://${CONTROL_PLANE_IP}:6443" \
    --output-dir "$OUT_DIR" \
    --install-image "factory.talos.dev/installer/${TALOS_SCHEMA}:${TALOS_VERSION}"

  log "Applying Talos configs to nodes"
  talosctl --talosconfig "$TALOSCONFIG" apply-config --insecure --nodes "$CONTROL_PLANE_IP" --file "$OUT_DIR/controlplane.yaml"
  talosctl --talosconfig "$TALOSCONFIG" apply-config --insecure --nodes "$WORKER_IP" --file "$OUT_DIR/worker.yaml"

  talosctl --talosconfig "$TALOSCONFIG" config endpoint "$CONTROL_PLANE_IP"
  talosctl --talosconfig "$TALOSCONFIG" config node "$CONTROL_PLANE_IP"

  log "Bootstrapping Talos cluster"
  talosctl --talosconfig "$TALOSCONFIG" bootstrap

  log "Fetching kubeconfig"
  KUBECONFIG_PATH="$HOME/.kube/${HOMELAB_NAME}-kubeconfig.yml"
  mkdir -p "$HOME/.kube"
  talosctl --talosconfig "$TALOSCONFIG" kubeconfig "$KUBECONFIG_PATH"
}

install_argocd_and_apps() {
  log "Installing ArgoCD"
  local K="--kubeconfig $KUBECONFIG_PATH"
  kubectl $K create namespace argocd --dry-run=client -o yaml | kubectl $K apply -f -
  kubectl $K apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  kubectl $K patch svc argocd-server -n argocd -p '{"spec": {"type": "ClusterIP"}}'

  log "Applying app-of-apps Application named ${HOMELAB_NAME}-apps"
  cat <<EOF | kubectl $K apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${HOMELAB_NAME}-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "https://github.com/IloveNooodles/citadel.git"
    targetRevision: main
    path: argocd/apps
  destination:
    server: "https://kubernetes.default.svc"
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
}

rename_vms() {
  log "Renaming VMs to include ${HOMELAB_NAME}"
  ssh_cmd "qm set 110 --name ${HOMELAB_NAME}-control-plane || true"
  ssh_cmd "qm set 111 --name ${HOMELAB_NAME}-worker-0 || true"
  ssh_cmd "qm set 101 --name ${HOMELAB_NAME}-omarchy || true"
}

print_outputs() {
  local K="--kubeconfig $KUBECONFIG_PATH"
  log "Fetching ArgoCD admin password"
  local ARGO_PW
  ARGO_PW=$(kubectl $K get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode || true)
  echo
  echo "Installation complete!"
  echo "- Homelab name: ${HOMELAB_NAME}"
  echo "- Control plane IP: ${CONTROL_PLANE_IP}"
  echo "- Worker IP: ${WORKER_IP}"
  echo "- Kubeconfig: ${KUBECONFIG_PATH}"
  if [[ -n "$ARGO_PW" ]]; then
    echo "- ArgoCD admin password: ${ARGO_PW}"
  else
    echo "- ArgoCD admin password not yet available. It will appear once pods are ready."
  fi
  echo
  echo "Next steps:"
  echo "  kubectl --kubeconfig ${KUBECONFIG_PATH} get nodes"
  echo "  kubectl --kubeconfig ${KUBECONFIG_PATH} -n argocd get pods"
  echo "  kubectl --kubeconfig ${KUBECONFIG_PATH} port-forward -n argocd svc/argocd-server 8080:443"
  echo "  Open https://localhost:8080 and login with 'admin' and the password above."
}

main() {
  preflight_checks
  prompt_inputs
  write_tfvars
  terraform_apply
  start_vms
  poll_ips
  talos_setup
  install_argocd_and_apps
  rename_vms
  print_outputs
}

main "$@"


