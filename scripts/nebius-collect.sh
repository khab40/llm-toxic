#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=nebius-common.sh
source "$SCRIPT_DIR/nebius-common.sh"

print_nebius_config

mkdir -p "$NEBIUS_LOCAL_EVIDENCE_DIR"

REMOTE_RUN_DIR="$NEBIUS_REMOTE_DIR/outputs_toxic/runs/$NEBIUS_RUN_NAME"

echo "Collecting evidence archive..."
scp_from_nebius "$REMOTE_RUN_DIR/evidence-$NEBIUS_RUN_NAME.tar.gz" "$NEBIUS_LOCAL_EVIDENCE_DIR/"

echo "Extracting evidence locally..."
tar -xzf "$NEBIUS_LOCAL_EVIDENCE_DIR/evidence-$NEBIUS_RUN_NAME.tar.gz" \
  -C "$NEBIUS_LOCAL_EVIDENCE_DIR"

echo "Collecting lightweight result files..."
scp_from_nebius "$REMOTE_RUN_DIR/nbconvert.log" "$NEBIUS_LOCAL_EVIDENCE_DIR/nbconvert.log" || true
scp_from_nebius "$REMOTE_RUN_DIR/toxic_homework.executed.ipynb" "$NEBIUS_LOCAL_EVIDENCE_DIR/toxic_homework.executed.ipynb" || true
scp_from_nebius "$REMOTE_RUN_DIR/outputs-file-list.tsv" "$NEBIUS_LOCAL_EVIDENCE_DIR/outputs-file-list.tsv" || true

echo "Evidence collected at: $NEBIUS_LOCAL_EVIDENCE_DIR"
