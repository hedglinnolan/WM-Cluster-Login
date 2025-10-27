@echo off
REM Quick login to Astral via bastion (no PowerShell policy needed)
REM Usage: Connect-Astral.cmd <WM_NETID>
set USER=%1
if "%USER%"=="" (
  set /p USER=Enter your W&M NetID: 
)
ssh -J %USER%@bastion.wm.edu %USER%@astral.sciclone.wm.edu
