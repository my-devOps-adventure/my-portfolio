#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-portfolio-staging}"
SECRET_NAME="${SECRET_NAME:-ghcr-pull-secret}"
USERNAME="${GHCR_PULL_USERNAME:-}"
TOKEN="${GHCR_PULL_TOKEN:-}"

if [ -z "${USERNAME}" ] || [ -z "${TOKEN}" ]; then
  echo "Usage: GHCR_PULL_USERNAME=your-github-user GHCR_PULL_TOKEN=ghp_... $0" >&2
  echo "PAT needs read:packages scope for ghcr.io/my-devops-adventure/portfolio." >&2
  exit 1
fi

if [ ! -f "${HOME}/.kube/config" ]; then
  echo "error: ~/.kube/config not found. Run ./scripts/setup-k3s-kubeconfig.sh first." >&2
  exit 1
fi

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret docker-registry "${SECRET_NAME}" \
  --docker-server=ghcr.io \
  --docker-username="${USERNAME}" \
  --docker-password="${TOKEN}" \
  --namespace="${NAMESPACE}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created/updated secret ${SECRET_NAME} in ${NAMESPACE}."
