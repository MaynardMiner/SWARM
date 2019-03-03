$dir = (Split-Path $script:MyInvocation.MyCommand.Path)
$ParseArgs = Get-Content ".\SWARM.bat"
$Arguments = $ParseArgs | Select-String "startup.ps1"
$Arguments -match "startup.ps1 (?<content>.*)`"" | Out-Null
$Arguments = $matches['content']

Start-Process "CMD" -ArgumentList "/C powershell -version 5.0 -noexit -executionpolicy Bypass -windowstyle maximized -command `"$dir\swarm.ps1 $Arguments`"" -Verb RunAs