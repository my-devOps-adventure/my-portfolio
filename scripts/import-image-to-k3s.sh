#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-ghcr.io/my-devops-adventure/portfolio:local}"
TAR="$(mktemp /tmp/portfolio-image.XXXXXX.tar)"

cleanup() {
  rm -f "${TAR}"
}
trap cleanup EXIT

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  echo "error: image ${IMAGE} not found. Build it first:" >&2
  echo "  docker build -t ${IMAGE} ." >&2
  exit 1
fi

echo "Saving ${IMAGE} to ${TAR}..."
docker save "${IMAGE}" -o "${TAR}"

echo "Importing into K3s..."
sudo k3s ctr images import "${TAR}"

echo "Done. Imported image:"
sudo k3s ctr images ls | grep -F "${IMAGE%%:*}" || true
