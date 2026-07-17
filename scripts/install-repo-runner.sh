#!/usr/bin/env bash
set -euo pipefail

# Install a repository-level self-hosted runner (recommended over org-level).
# Get a fresh registration token from:
#   my-portfolio -> Settings -> Actions -> Runners -> New self-hosted runner

REPO_URL="${REPO_URL:-https://github.com/my-devOps-adventure/my-portfolio}"
RUNNER_DIR="${RUNNER_DIR:-${HOME}/Desktop/actions-runner}"
RUNNER_NAME="${RUNNER_NAME:-k3s-staging-runner}"
RUNNER_LABELS="${RUNNER_LABELS:-k3s-staging}"
RUNNER_VERSION="${RUNNER_VERSION:-2.335.1}"
TOKEN="${RUNNER_TOKEN:-}"

if [ -z "${TOKEN}" ]; then
  echo "Usage: RUNNER_TOKEN=token_from_github_ui $0" >&2
  echo "Get the token from: ${REPO_URL}/settings/actions/runners/new" >&2
  exit 1
fi

mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

if [ ! -f ./config.sh ]; then
  curl -o actions-runner.tar.gz -L \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  tar xzf actions-runner.tar.gz
fi

./config.sh \
  --url "${REPO_URL}" \
  --token "${TOKEN}" \
  --labels "${RUNNER_LABELS}" \
  --name "${RUNNER_NAME}" \
  --unattended \
  --replace

sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status

echo
echo "Runner installed for repository ${REPO_URL} with label ${RUNNER_LABELS}."
