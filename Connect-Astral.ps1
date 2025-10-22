\
param(
  [string]$User = "YOUR_NETID"
)
# Quick login to Astral front-end from off-campus via bastion (ProxyJump)
ssh -J "$User@bastion.wm.edu" "$User@astral.sciclone.wm.edu"
