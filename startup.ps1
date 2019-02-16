$dir = (Split-Path $script:MyInvocation.MyCommand.Path)
$ParseArgs = Get-Content ".\SWARM.bat"
$ParseArgs -match "startup.ps1 (?<content>.*)`"" | Out-Null
$ParseArgs = $matches['content']

Start-Process "CMD" -ArgumentList "/C powershell -version 5.0 -noexit -executionpolicy Bypass -windowstyle maximized -command `"$dir\swarm.ps1 $ParseArgs`"" -Verb RunAs