#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NEBIUS_USER="${NEBIUS_USER:-}"
NEBIUS_HOST="${NEBIUS_HOST:-}"
NEBIUS_REMOTE_DIR="${NEBIUS_REMOTE_DIR:-~/llm-toxic}"
NEBIUS_PYTHON="${NEBIUS_PYTHON:-python3}"
NEBIUS_INSTALL_DEPS="${NEBIUS_INSTALL_DEPS:-1}"
NEBIUS_NOTEBOOK_TIMEOUT="${NEBIUS_NOTEBOOK_TIMEOUT:--1}"
NEBIUS_RUN_NAME="${NEBIUS_RUN_NAME:-$(date -u +%Y%m%dT%H%M%SZ)}"
NEBIUS_LOCAL_EVIDENCE_DIR="${NEBIUS_LOCAL_EVIDENCE_DIR:-$PROJECT_ROOT/evidence/nebius/$NEBIUS_RUN_NAME}"

if [[ -n "${NEBIUS_SSH_TARGET:-}" ]]; then
  SSH_TARGET="$NEBIUS_SSH_TARGET"
elif [[ -n "$NEBIUS_USER" && -n "$NEBIUS_HOST" ]]; then
  SSH_TARGET="$NEBIUS_USER@$NEBIUS_HOST"
else
  echo "Set NEBIUS_USER and NEBIUS_HOST, or set NEBIUS_SSH_TARGET." >&2
  exit 2
fi

SSH_OPTS=(-o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=10)
if [[ -n "${NEBIUS_SSH_KEY:-}" ]]; then
  SSH_OPTS+=(-i "$NEBIUS_SSH_KEY")
fi

ssh_nebius() {
  ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "$@"
}

scp_from_nebius() {
  scp "${SSH_OPTS[@]}" "$SSH_TARGET:$1" "$2"
}

scp_to_nebius() {
  scp "${SSH_OPTS[@]}" "$1" "$SSH_TARGET:$2"
}

print_nebius_config() {
  cat <<EOF
Nebius target:       $SSH_TARGET
Remote directory:    $NEBIUS_REMOTE_DIR
Run name:            $NEBIUS_RUN_NAME
Local evidence dir:  $NEBIUS_LOCAL_EVIDENCE_DIR
Install deps:        $NEBIUS_INSTALL_DEPS
Notebook timeout:    $NEBIUS_NOTEBOOK_TIMEOUT
EOF
}
