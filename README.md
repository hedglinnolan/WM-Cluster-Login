# Jupyter on W&M Astral (Windows, Off‑Campus) — Quick Start

This README packages everything you need to run **Jupyter Lab on the Astral cluster** (not on your laptop), with a simple project layout so your notebooks can `import` your own Python files. It assumes **Windows 10/11** with built‑in OpenSSH and that you're **off‑campus**. No VPN is required if you use the W&M **bastion** jump host.

---

## What’s included (download these)
- `wm-jupy.yml` — Conda environment spec (Python 3.12 + JupyterLab + common data stack)
- `wm-jupy-gpu.yml` — (Optional) GPU environment spec for Astral’s A30 node
- `launch_jupyter_astral.sh` — Remote script to request a Slurm node and start Jupyter
- `Open-AstralJupyterTunnel.cmd` — Windows helper to open the SSH tunnel to Jupyter
- `Connect-Astral.ps1` — Windows helper to log in to Astral (via bastion)
  > If your organization blocks `.ps1` files, use `Connect-Astral.cmd` instead.
- `ssh_config_sample.txt` — Optional SSH config to stop re‑typing your username

> If you haven’t yet, download these files from ChatGPT and keep them together locally.

---

## First‑Time Setup

### 1) Log in to Astral (off‑campus) from Windows
Open **PowerShell** and run:
```powershell
# If PowerShell scripts are allowed:
.\Connect-Astral.ps1 -User YOUR_NETID

# If blocked by execution policy, use the .cmd instead:
.\Connect-Astral.cmd YOUR_NETID
```
This uses the bastion jump host under the hood. You’ll approve Duo and land on `astral.sciclone.wm.edu`.

### 2) Copy the env + launch script to Astral
In another PowerShell window (on your PC), from the directory where you downloaded these files:
```powershell
scp -J YOUR_NETID@bastion.wm.edu `
    .\wm-jupy.yml .\wm-jupy-gpu.yml .\launch_jupyter_astral.sh `
    YOUR_NETID@astral.sciclone.wm.edu:~/
```
Then, in your Astral shell:
```bash
mkdir -p ~/bin
mv ~/launch_jupyter_astral.sh ~/bin/
chmod +x ~/bin/launch_jupyter_astral.sh
```

### 3) Create the conda environment(s) (on Astral)
**Tip:** Astral’s default login shell is `tcsh`. To keep things simple, switch to Bash first.

```bash
# switch to bash for the setup session
bash

# initialize Environment Modules for bash, then load Miniforge (conda)
source /usr/share/Modules/init/bash
module load miniforge3/24.9.2-0

# CPU env
conda env create -n wm-jupy -f ~/wm-jupy.yml
conda run -n wm-jupy python -m ipykernel install --user --name wm-jupy --display-name "wm-jupy (Astral)"

# GPU env (optional, recommended for work on node as01)
conda env create -n wm-jupy-gpu -f ~/wm-jupy-gpu.yml
conda run -n wm-jupy-gpu python -m ipykernel install --user --name wm-jupy-gpu --display-name "wm-jupy-gpu (Astral)"
```

> If modules/conda init complains, you can still launch later using your env’s Python directly at `~/.conda/envs/<env>/bin/python` (the launcher supports this).

### 4) Create a project layout that supports imports
Put code in `src/myproj/` so notebooks can `import myproj` cleanly.

```bash
mkdir -p /sciclone/scr10/$USER/myproj/{notebooks,src/myproj,tests,data}
touch /sciclone/scr10/$USER/myproj/src/myproj/__init__.py

# optional but recommended: install your package in editable mode
~/.conda/envs/wm-jupy/bin/python -m pip install -e /sciclone/scr10/$USER/myproj
```
A typical tree looks like:
```
/sciclone/scr10/$USER/myproj
├─ notebooks/
├─ src/
│  └─ myproj/
│     ├─ __init__.py
│     └─ utils.py
└─ tests/
```
In a notebook:
```python
from myproj.utils import some_helper
```

---

## Daily Workflow

### A) Start Jupyter on a compute node (Astral)
1. Log in:
   ```powershell
   # .ps1 (if allowed):   .\Connect-Astral.ps1 -User YOUR_NETID
   # or .cmd:             .\Connect-Astral.cmd YOUR_NETID
   ```
2. On Astral, run the launcher (choose CPUs/GPU/time as needed):
   ```bash
   # CPU example:
   bash ~/bin/launch_jupyter_astral.sh wm-jupy 8890 "-n 4 -t 02:00:00"

   # GPU example (uses node as01):
   bash ~/bin/launch_jupyter_astral.sh wm-jupy-gpu 8890 "--gpus=1 -n 4 -t 02:00:00"
   ```
   The script will:
   - request a Slurm allocation (`salloc`) and run on the compute node via `srun`
   - print the **node** (e.g., `as01.sciclone.wm.edu` or `astral.sciclone.wm.edu`) and **port**
   - start Jupyter as `python -m jupyterlab.labapp --no-browser --ip=0.0.0.0 --port=<PORT>`

### B) Open the tunnel from your Windows PC
In a second PowerShell window (on your PC):
```powershell
# Use the .cmd helper (recommended). Replace NODE with what the launcher printed.
.\Open-AstralJupyterTunnel.cmd YOUR_NETID as01.sciclone.wm.edu 8890

# Or raw ssh (same effect):
ssh -J YOUR_NETID@bastion.wm.edu -N -L 8890:as01.sciclone.wm.edu:8890 YOUR_NETID@astral.sciclone.wm.edu
```
Now open the URL printed by Jupyter in your browser, but change the host to `127.0.0.1`, for example:
```
http://127.0.0.1:8890/lab?token=...
```

### C) Stop re‑typing your username (optional)
Edit `Open-AstralJupyterTunnel.cmd`/`Connect-Astral.ps1` to set your default NetID, **or** save `ssh_config_sample.txt` as `C:\Users\<you>\.ssh\config`. Then you can:
```powershell
ssh wm-astral
ssh -N -L 8890:as01.sciclone.wm.edu:8890 wm-astral
```

---

## Tips & Variations

- **Change the port**: If 8890 is busy, pick another and use it both in the launcher and the tunnel (e.g., `8892`). The launcher also retries nearby ports with `--ServerApp.port_retries=50`.
- **GPU work**: GPUs live on `as01`. Launch with `--gpus=1` and use the **wm-jupy-gpu** kernel in Jupyter.
- **Where to store data/code**: Use `/sciclone/scr10/$USER` (global scratch) for most work. Heavy I/O during a job benefits from node‑local scratch if available.
- **VS Code Remote‑SSH**: You can Remote‑SSH into `astral.sciclone.wm.edu` and still run the same Jupyter steps; compute remains on the Slurm node.

---

## Troubleshooting

- **PowerShell blocked .ps1**: Use the `.cmd` wrappers, or run:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Connect-Astral.ps1 -User YOUR_NETID
  ```
- **No token / lost token**:
  ```bash
  # On Astral (replace env if needed)
  conda run -n wm-jupy jupyter server list
  ```
- **Browser can’t reach page**: Keep the Jupyter terminal **open** on Astral; keep the tunnel window **open** on Windows; browse `http://127.0.0.1:<port>/lab?...`. Ensure the node/port in your `-L` match Jupyter’s output.
- **Conda not found / modules error**: The launcher bypasses conda shell hooks by calling your env python directly:
  ```bash
  ~/.conda/envs/<env>/bin/python -m jupyterlab.labapp --no-browser --ip=0.0.0.0 --port=<PORT> --ServerApp.port_retries=50
  ```
- **Imports fail in notebooks**: Ensure you installed your project with `pip install -e /sciclone/scr10/$USER/myproj` and that the package lives under `src/myproj/`.
- **Port already in use**: Try a new port (8892, 8894) in **both** the launcher and the tunnel; or stop old servers:
  ```bash
  conda run -n wm-jupy-gpu jupyter server list
  conda run -n wm-jupy-gpu jupyter server stop 8890
  ```

---

## Under the Hood (reference)

- **Interactive allocation**: `salloc -n 4 -t 02:00:00 [--gpus=1]` then `srun --pty -n 1 bash -l`
- **Jupyter server**: `python -m jupyterlab.labapp --no-browser --ip=0.0.0.0 --port=<PORT> --ServerApp.port_retries=50`
- **SSH tunnel (ProxyJump)**: `ssh -J <netid>@bastion.wm.edu -N -L <PORT>:<NODE>:<PORT> <netid>@astral.sciclone.wm.edu`

---

## Appendix: Minimal `pyproject.toml` (optional but recommended)

Put this in `/sciclone/scr10/$USER/myproj/pyproject.toml` to make your package discoverable:
```toml
[project]
name = "myproj"
version = "0.0.1"
requires-python = ">=3.10"

[build-system]
requires = ["setuptools>=61"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
where = ["src"]
```
Then run: `~/.conda/envs/wm-jupy/bin/python -m pip install -e /sciclone/scr10/$USER/myproj`

---

**You’re set.** Start the launcher on Astral, open the tunnel locally, and work in Jupyter knowing everything runs on the cluster.
