#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=nebius-common.sh
source "$SCRIPT_DIR/nebius-common.sh"

print_nebius_config

ARCHIVE="$PROJECT_ROOT/.nebius-deploy.tar.gz"
cleanup() {
  rm -f "$ARCHIVE"
}
trap cleanup EXIT

echo "Creating deployment archive..."
tar \
  --exclude '.git' \
  --exclude '.venv' \
  --exclude '.ipynb_checkpoints' \
  --exclude 'outputs_toxic' \
  --exclude 'evidence' \
  --exclude '.nebius-deploy.tar.gz' \
  -czf "$ARCHIVE" \
  -C "$PROJECT_ROOT" .

echo "Preparing remote directory..."
ssh_nebius "mkdir -p $NEBIUS_REMOTE_DIR"

echo "Uploading archive..."
scp_to_nebius "$ARCHIVE" "$NEBIUS_REMOTE_DIR/project.tar.gz"

echo "Extracting on remote..."
ssh_nebius "cd $NEBIUS_REMOTE_DIR && tar -xzf project.tar.gz && rm -f project.tar.gz"

echo "Deployment complete."
