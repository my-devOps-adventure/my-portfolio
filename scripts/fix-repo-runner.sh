#!/usr/bin/env bash
set -euo pipefail

# Re-register the local runner for my-portfolio (repo-level) with the k3s-staging label.
# Get a fresh token from:
#   https://github.com/my-devOps-adventure/my-portfolio/settings/actions/runners/new

REPO_URL="https://github.com/my-devOps-adventure/my-portfolio"
RUNNER_DIR="${RUNNER_DIR:-${HOME}/Desktop/actions-runner}"
RUNNER_NAME="${RUNNER_NAME:-bzinedda}"
TOKEN="${RUNNER_TOKEN:-}"

if [ -z "${TOKEN}" ]; then
  echo "Usage: RUNNER_TOKEN=token_from_github $0" >&2
  echo "Get token: ${REPO_URL}/settings/actions/runners/new" >&2
  exit 1
fi

mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

if [ ! -f ./config.sh ]; then
  echo "error: ${RUNNER_DIR} is not a runner install. Download the runner tarball first." >&2
  exit 1
fi

echo "Stopping any existing runner service..."
sudo ./svc.sh stop 2>/dev/null || true
sudo ./svc.sh uninstall 2>/dev/null || true
pkill -f 'Runner.Listener' 2>/dev/null || true
sleep 2

echo "Registering repo runner with label k3s-staging..."
./config.sh \
  --url "${REPO_URL}" \
  --token "${TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "k3s-staging" \
  --unattended \
  --replace

echo
echo "Runner config:"
grep -E 'gitHubUrl|agentName' .runner

if ! grep -q 'my-portfolio' .runner; then
  echo "error: runner is not registered to my-portfolio repo." >&2
  exit 1
fi

echo
echo "Installing and starting service..."
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status

echo
echo "Done. Confirm in GitHub: ${REPO_URL}/settings/actions/runners"
echo "Runner should show labels: self-hosted, Linux, X64, k3s-staging"
