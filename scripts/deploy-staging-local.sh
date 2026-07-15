#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/my-devops-adventure/portfolio}"
IMAGE_TAG="${IMAGE_TAG:-local}"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
KUBECONFIG="${KUBECONFIG:-${HOME}/.kube/config}"

if [ ! -f "${KUBECONFIG}" ]; then
  echo "error: ${KUBECONFIG} not found. Run ./scripts/setup-k3s-kubeconfig.sh first." >&2
  exit 1
fi

export KUBECONFIG

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "error: kubectl cannot reach the cluster. Run ./scripts/setup-k3s-kubeconfig.sh" >&2
  exit 1
fi

if ! sudo k3s ctr images ls | grep -Fq "${FULL_IMAGE}"; then
  echo "error: ${FULL_IMAGE} is not loaded in K3s." >&2
  echo "Run: ./scripts/import-image-to-k3s.sh ${FULL_IMAGE}" >&2
  exit 1
fi

echo "Deploying ${FULL_IMAGE} with imagePullPolicy=Never (local image only)..."

kubectl kustomize "${ROOT_DIR}/k8s/staging" \
  | sed "s#ghcr.io/example/portfolio:latest#${FULL_IMAGE}#g" \
  | sed 's#imagePullPolicy: Always#imagePullPolicy: Never#g' \
  | kubectl apply --validate=false -f -

kubectl rollout restart deployment/portfolio --namespace portfolio-staging
kubectl rollout status deployment/portfolio --namespace portfolio-staging --timeout=180s
kubectl get pods,svc,ingress -n portfolio-staging

echo
echo "If ingress host is portfolio.local, add this to /etc/hosts:"
echo "127.0.0.1 portfolio.local"
echo
echo "Then test: curl -s http://portfolio.local/healthz"
