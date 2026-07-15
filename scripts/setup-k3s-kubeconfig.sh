#!/usr/bin/env bash
set -euo pipefail

K3S_KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
USER_KUBECONFIG="${HOME}/.kube/config"
SERVER_HOST="${1:-}"

if [ ! -f "${K3S_KUBECONFIG}" ]; then
  echo "error: ${K3S_KUBECONFIG} not found. Install K3s first." >&2
  exit 1
fi

mkdir -p "${HOME}/.kube"
sudo cp "${K3S_KUBECONFIG}" "${USER_KUBECONFIG}"
sudo chown "$(id -u):$(id -g)" "${USER_KUBECONFIG}"
chmod 600 "${USER_KUBECONFIG}"
export KUBECONFIG="${USER_KUBECONFIG}"

if [ -n "${SERVER_HOST}" ]; then
  sed -i "s#https://127.0.0.1:6443#https://${SERVER_HOST}:6443#g" "${USER_KUBECONFIG}"
  echo "Updated kubeconfig server to https://${SERVER_HOST}:6443"
fi

echo "Testing cluster access..."
kubectl cluster-info
kubectl get nodes

echo
echo "GitHub secret value (copy all of this into K3S_KUBECONFIG_B64):"
base64 -w 0 "${USER_KUBECONFIG}"
echo
