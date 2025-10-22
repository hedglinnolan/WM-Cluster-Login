\
param(
  [string]$User = "YOUR_NETID",
  [string]$Node = "as01",   # Replace with the node printed by the launch script (e.g., 'astral' or 'as01')
  [int]$Port = 8888
)
# Open a local tunnel to the remote Jupyter server running on Astral via bastion.
# Example: .\Open-AstralJupyterTunnel.ps1 -User yourid -Node as01 -Port 8888
ssh -J "$User@bastion.wm.edu" -N -L $Port:$Node:$Port "$User@astral.sciclone.wm.edu"
