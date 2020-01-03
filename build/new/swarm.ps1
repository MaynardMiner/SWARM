Using namespace System
Using module ".\core\swarm.psm1";

## For now
[string]$Global:dir = (Split-Path $script:MyInvocation.MyCommand.Path)
Set-location $dir

[SWARM]::main($args);