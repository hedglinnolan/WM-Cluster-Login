@echo off
REM Open a local tunnel to remote Jupyter on Astral via bastion (no PowerShell policy needed)
REM Usage: Open-AstralJupyterTunnel.cmd <WM_NETID> <NODE> [PORT]
REM Example: Open-AstralJupyterTunnel.cmd jdoe as01 8888
set USER=%1
set NODE=%2
set PORT=%3
if "%USER%"=="" (
  set /p USER=Enter your W&M NetID: 
)
if "%NODE%"=="" (
  set /p NODE=Enter compute node (e.g., as01 or astral): 
)
if "%PORT%"=="" (
  set PORT=8888
)
echo Opening tunnel on local port %PORT% to %NODE%: %PORT% ...
ssh -J %USER%@bastion.wm.edu -N -L %PORT%:%NODE%:%PORT% %USER%@astral.sciclone.wm.edu
