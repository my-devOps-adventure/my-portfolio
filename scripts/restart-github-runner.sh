#!/usr/bin/env bash
set -euo pipefail

RUNNER_DIR="${RUNNER_DIR:-${HOME}/Desktop/actions-runner}"

if [ ! -d "${RUNNER_DIR}" ]; then
  echo "error: runner directory not found: ${RUNNER_DIR}" >&2
  exit 1
fi

cd "${RUNNER_DIR}"

echo "Restarting GitHub Actions runner service..."
sudo ./svc.sh stop
sleep 2
sudo ./svc.sh start
sudo ./svc.sh status

echo
echo "Recent listener log lines:"
journalctl -u "$(basename "$(ls /etc/systemd/system/actions.runner.*.service | head -1)")" --no-pager -n 10 2>/dev/null \
  || grep -E 'Listening for Jobs|Running job|connect error' _diag/Runner_*.log | tail -5
