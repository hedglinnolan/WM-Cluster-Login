# Jupyter on W&M Astral (Windows, Off‑Campus) — Quick Start

This README packages everything you need to run **Jupyter Lab on the Astral cluster** (not on your laptop), with a simple project layout so your notebooks can `import` your own Python files. It assumes **Windows 10/11** with built‑in OpenSSH and that you're **off‑campus**. No VPN is required if you use the W&M **bastion** jump host.

---

## What’s included (download these)
- `wm-jupy.yml` — Conda environment spec (Python 3.12 + JupyterLab + common data stack)
- `launch_jupyter_astral.sh` — Remote script to request a Slurm node and start Jupyter
- `Open-AstralJupyterTunnel.ps1` — Windows helper to open the SSH tunnel to Jupyter
- `Connect-Astral.ps1` — Windows helper to log in to Astral (via bastion)
- `ssh_config_sample.txt` — Optional SSH config to stop re‑typing your username

> If you haven’t yet, download these files from ChatGPT and keep them together locally.

---

## First‑Time Setup

### 1) Log in to Astral (off‑campus) from Windows
Open **PowerShell** and run:
```powershell
.\Connect-Astral.ps1 -User YOUR_NETID
```
This uses the bastion jump host under the hood. You’ll approve Duo and land on `astral.sciclone.wm.edu`.

### 2) Copy the env + launch script to Astral
In another PowerShell window (on your PC), from the directory where you downloaded these files:
```powershell
scp -J YOUR_NETID@bastion.wm.edu `
    .\wm-jupy.yml .\launch_jupyter_astral.sh `
    YOUR_NETID@astral.sciclone.wm.edu:~/
```
Then, in your Astral shell:
```bash
mkdir -p ~/bin
mv ~/launch_jupyter_astral.sh ~/bin/
chmod +x ~/bin/launch_jupyter_astral.sh
```

### 3) Create the conda environment (on Astral)
```bash
module load miniforge3
conda env create -n wm-jupy -f ~/wm-jupy.yml
conda activate wm-jupy
python -m ipykernel install --user --name wm-jupy --display-name "wm-jupy (Astral)"
```

### 4) Create a project layout that supports imports
Put code in `src/myproj/` so notebooks can `import myproj` cleanly.

```bash
mkdir -p /sciclone/scr10/$USER/myproj/{notebooks,src/myproj,tests,data}
touch /sciclone/scr10/$USER/myproj/src/myproj/__init__.py

# optional but recommended: install your package in editable mode
python -m pip install -e /sciclone/scr10/$USER/myproj
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
   .\Connect-Astral.ps1 -User YOUR_NETID
   ```
2. On Astral, run the launch script (choose CPUs/GPU/time as needed):
   ```bash
   bash ~/bin/launch_jupyter_astral.sh wm-jupy 8888 "-n 4 -t 02:00:00"
   # GPU example:
   # bash ~/bin/launch_jupyter_astral.sh wm-jupy 8888 "--gpus=1 -n 4 -t 02:00:00"
   ```
   The script will:
   - load `miniforge3`
   - activate `wm-jupy`
   - request a Slurm allocation (`salloc`)
   - print the **node** (e.g., `as01` or `astral`) and **port**
   - start `jupyter lab --no-browser --ip=0.0.0.0 --port=8888`

### B) Open the tunnel from your Windows PC
In a second PowerShell window (on your PC):
```powershell
.\Open-AstralJupyterTunnel.ps1 -User YOUR_NETID -Node as01 -Port 8888
# Replace 'as01' with the node printed by the launch script.
```
Now open the URL printed by Jupyter in your browser, but change the host to `127.0.0.1`, for example:
```
http://127.0.0.1:8888/lab?token=...
```

### C) Stop re‑typing your username (optional)
Edit `Open-AstralJupyterTunnel.ps1` and `Connect-Astral.ps1` and set the default:
```powershell
param([string]$User = "YOUR_NETID", ...)
```
Or save `ssh_config_sample.txt` as `C:\Users\<you>\.ssh\config` with your netid. Then you can:
```powershell
ssh wm-astral
ssh -N -L 8888:as01:8888 wm-astral
```

---

## Tips & Variations

- **Change the port**: If 8888 is busy, pick another and use it both in the launch script and the tunnel (`-Port 8890`).
- **GPU work**: Astral GPUs are on `as01`. Request them with `--gpus=1` (or more) in the third arg to the launch script.
- **Where to store data/code**: Use `/sciclone/scr10/$USER` (global scratch) for most work. Heavy I/O during a job benefits from node‑local scratch if available.
- **VS Code Remote‑SSH**: You can Remote‑SSH into `astral.sciclone.wm.edu` and still run the same Jupyter steps; compute will remain on the Slurm node.

---

## Troubleshooting

- **No connection / timeouts**: Make sure you used the bastion jump (`Connect-Astral.ps1`) and that Duo prompts succeed.
- **Blank page**: Keep the Jupyter terminal **open** on Astral; open the tunnel in a second window; browse `http://127.0.0.1:<port>/lab?...`.
- **Conda not found**: Run `module load miniforge3` before creating/activating the env.
- **Imports fail in notebooks**: Ensure you installed your project with `pip install -e /sciclone/scr10/$USER/myproj` and the package lives under `src/myproj/`.
- **Port already in use**: Switch to a free port, e.g., `8890` in both the launch script and tunnel command.

---

## Under the Hood (reference)

- **Interactive allocation**: `salloc -n 4 -t 02:00:00 [--gpus=1]`
- **Jupyter server**: `jupyter lab --no-browser --ip=0.0.0.0 --port=<PORT>`
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
Then run: `python -m pip install -e /sciclone/scr10/$USER/myproj`

---

**You’re set.** Start the launch script on Astral, open the tunnel locally, and work in Jupyter knowing everything runs on the cluster.
