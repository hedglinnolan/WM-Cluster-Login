#!/usr/bin/env bash
# Astral Jupyter launcher — runs Jupyter on the compute node via salloc+srun.
# Calls your env's python directly (no conda hook needed).
#
# Usage:
#   bash ~/bin/launch_jupyter_astral.sh [ENV_NAME] [PORT] [SLURM_OPTS]
# Examples:
#   bash ~/bin/launch_jupyter_astral.sh wm-jupy 8890 "-n 4 -t 02:00:00"
#   bash ~/bin/launch_jupyter_astral.sh wm-jupy-gpu 8890 "--gpus=1 -n 4 -t 02:00:00"

set -euo pipefail
ENV_NAME="${1:-wm-jupy}"
PORT="${2:-8890}"
SLURM_OPTS="${3:-"-n 4 -t 02:00:00"}"

# Project root on fast scratch; fall back to home
if   [ -d "/sciclone/scr10/$USER" ]; then PROJECT_ROOT="/sciclone/scr10/$USER/myproj"
elif [ -d "/sciclone/scr20/$USER" ]; then PROJECT_ROOT="/sciclone/scr20/$USER/myproj"
else PROJECT_ROOT="$HOME/myproj"
fi
mkdir -p "$PROJECT_ROOT/notebooks"

# Path to the env's python (avoids conda shell hooks)
ENV_PY="$HOME/.conda/envs/$ENV_NAME/bin/python"
if [ ! -x "$ENV_PY" ]; then
  echo "ERROR: $ENV_PY not found/executable. Create env '$ENV_NAME' or fix path." >&2
  echo "Hint:  conda env list   and   conda env create -n $ENV_NAME -f ~/wm-jupy[-gpu].yml" >&2
  exit 1
fi

echo "Allocating: salloc $SLURM_OPTS"
salloc $SLURM_OPTS srun --pty bash -lc '
  set -euo pipefail
  cd "'"$PROJECT_ROOT"'/notebooks"
  NODE=$(hostname)
  echo NODE:$NODE
  echo REQUESTED_PORT:'"$PORT"'  # Jupyter may try nearby ports if busy
  # Run Jupyter from the env directly; auto-retry ports if busy
  exec "'"$ENV_PY"'" -m jupyterlab.labapp \
       --no-browser --ip=0.0.0.0 --port='"$PORT"' --ServerApp.port_retries=50
'
