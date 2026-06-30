#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/nebius-deploy.sh"
"$SCRIPT_DIR/nebius-run.sh"
"$SCRIPT_DIR/nebius-collect.sh"
