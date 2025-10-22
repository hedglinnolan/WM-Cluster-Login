#!/usr/bin/env bash
# Launch Jupyter Lab on an Astral compute node via Slurm.
# Usage (on astral after ssh): bash ~/bin/launch_jupyter_astral.sh [ENV_NAME] [PORT] [SLURM_OPTS]
# Examples:
#   bash ~/bin/launch_jupyter_astral.sh
#   bash ~/bin/launch_jupyter_astral.sh wm-jupy 8888 "--gpus=1 -n 4 -t 02:00:00"
# Environment variables you may want to set before running:
#   PROJECT_ROOT   (default: /sciclone/scr10/$USER/myproj)
#   NOTEBOOK_DIR   (default: $PROJECT_ROOT/notebooks)
set -euo pipefail

ENV_NAME="${1:-wm-jupy}"
PORT="${2:-8888}"
SLURM_OPTS="${3:-"-n 4 -t 02:00:00"}"

PROJECT_ROOT="${PROJECT_ROOT:-/sciclone/scr10/$USER/myproj}"
NOTEBOOK_DIR="${NOTEBOOK_DIR:-$PROJECT_ROOT/notebooks}"

# Load conda tooling (miniforge3) per W&M guidance
module load miniforge3 >/dev/null 2>&1 || true

# Ensure conda is available in non-interactive shells
if command -v conda >/dev/null 2>&1; then
  # shellcheck disable=SC1091
  source "$(conda info --base)/etc/profile.d/conda.sh"
  conda activate "$ENV_NAME"
else
  echo "ERROR: conda not found. Try: module load miniforge3" >&2
  exit 1
fi

mkdir -p "$NOTEBOOK_DIR"
cd "$NOTEBOOK_DIR"

echo "Requesting interactive Slurm allocation on Astral with: salloc $SLURM_OPTS"
# Open an interactive allocation and start Jupyter on the allocated node
salloc $SLURM_OPTS bash -lc "
  echo '--- Allocation granted on node:' \$(hostname)
  echo '--- Starting Jupyter Lab on port: $PORT'
  echo NODE:\$(hostname)
  echo PORT:$PORT
  jupyter lab --no-browser --ip=0.0.0.0 --port=$PORT
"
