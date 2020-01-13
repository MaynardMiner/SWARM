Using namespace System
Using module ".\core\swarm.psm1";

## Environment
$Dir = [IO.Path]::GetDirectoryName($script:MyInvocation.MyCommand.Path)
$Dir = [IO.Path]::GetDirectoryName($Dir)
$Target1 = [EnvironmentVariableTarget]::Machine
$Target2 = [EnvironmentVariableTarget]::Process
[environment]::SetEnvironmentVariable('SWARM_DIR', $Dir, $Target1)
[environment]::SetEnvironmentVariable('SWARM_DIR', $Dir, $Target2)
Set-Location $env:SWARM_DIR

[SWARM]::main($args);