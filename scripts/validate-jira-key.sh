#!/usr/bin/env bash
set -euo pipefail

JIRA_KEY_PATTERN='BZINEDDA-[0-9]+'

candidate_text="${1:-}"

if [[ -z "$candidate_text" ]]; then
  echo "Usage: validate-jira-key.sh '<branch, commit, or PR title text>'" >&2
  exit 2
fi

if [[ "$candidate_text" =~ $JIRA_KEY_PATTERN ]]; then
  echo "Found Jira key: ${BASH_REMATCH[0]}"
  exit 0
fi

echo "Missing Jira key. Include a key like BZINEDDA-107 in branches, commits, and PR titles." >&2
exit 1
