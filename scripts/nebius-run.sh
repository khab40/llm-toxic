#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=nebius-common.sh
source "$SCRIPT_DIR/nebius-common.sh"

print_nebius_config

REMOTE_SCRIPT=$(cat <<'REMOTE'
set -euo pipefail

REMOTE_DIR_EXPANDED="${NEBIUS_REMOTE_DIR/#\~/$HOME}"
cd "$REMOTE_DIR_EXPANDED"

RUN_DIR="outputs_toxic/runs/$NEBIUS_RUN_NAME"
mkdir -p "$RUN_DIR"

{
  echo "run_name=$NEBIUS_RUN_NAME"
  echo "started_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "host=$(hostname)"
  echo "pwd=$(pwd)"
  echo "python=$NEBIUS_PYTHON"
} > "$RUN_DIR/run.env"

if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi > "$RUN_DIR/nvidia-smi.before.txt" || true
  nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version,cuda_version --format=csv \
    > "$RUN_DIR/gpu-query.before.csv" || true
else
  echo "nvidia-smi not found" > "$RUN_DIR/nvidia-smi.before.txt"
  echo "nvidia-smi not found" > "$RUN_DIR/gpu-query.before.csv"
fi

if [[ ! -d .venv ]]; then
  "$NEBIUS_PYTHON" -m venv .venv
fi

source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel

if [[ "$NEBIUS_INSTALL_DEPS" == "1" ]]; then
  python -m pip install -r requirements.txt
fi

python -m pip freeze > "$RUN_DIR/pip-freeze.txt"
python - <<'PY' > "$RUN_DIR/python-env.txt"
import platform
try:
    import torch
    print("torch:", torch.__version__)
    print("cuda_available:", torch.cuda.is_available())
    print("cuda_device_count:", torch.cuda.device_count())
    if torch.cuda.is_available():
        print("cuda_device_name:", torch.cuda.get_device_name(0))
except Exception as exc:
    print("torch_probe_error:", repr(exc))
print("python:", platform.python_version())
print("platform:", platform.platform())
PY

set +e
jupyter nbconvert \
  --to notebook \
  --execute toxic_homework.ipynb \
  --ExecutePreprocessor.timeout="$NEBIUS_NOTEBOOK_TIMEOUT" \
  --output "$RUN_DIR/toxic_homework.executed.ipynb" \
  > "$RUN_DIR/nbconvert.log" 2>&1
STATUS=$?
set -e

if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi > "$RUN_DIR/nvidia-smi.after.txt" || true
else
  echo "nvidia-smi not found" > "$RUN_DIR/nvidia-smi.after.txt"
fi

find outputs_toxic -maxdepth 4 -type f -printf '%p\t%s\n' \
  > "$RUN_DIR/outputs-file-list.tsv" || true

{
  echo "finished_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "exit_status=$STATUS"
} >> "$RUN_DIR/run.env"

EVIDENCE_FILES=(
  run.env
  nvidia-smi.before.txt
  gpu-query.before.csv
  nvidia-smi.after.txt
  pip-freeze.txt
  python-env.txt
  nbconvert.log
  outputs-file-list.tsv
)
if [[ -f "$RUN_DIR/toxic_homework.executed.ipynb" ]]; then
  EVIDENCE_FILES+=(toxic_homework.executed.ipynb)
fi
tar -czf "$RUN_DIR/evidence-$NEBIUS_RUN_NAME.tar.gz" \
  -C "$RUN_DIR" \
  "${EVIDENCE_FILES[@]}"

exit "$STATUS"
REMOTE
)

ssh_nebius \
  "NEBIUS_REMOTE_DIR='$NEBIUS_REMOTE_DIR' NEBIUS_RUN_NAME='$NEBIUS_RUN_NAME' NEBIUS_PYTHON='$NEBIUS_PYTHON' NEBIUS_INSTALL_DEPS='$NEBIUS_INSTALL_DEPS' NEBIUS_NOTEBOOK_TIMEOUT='$NEBIUS_NOTEBOOK_TIMEOUT' bash -s" \
  <<< "$REMOTE_SCRIPT"
