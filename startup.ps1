$dir = Split-Path $script:MyInvocation.MyCommand.Path
$ParseArgs = Get-Content ".\SWARM.bat"
$Arguments = $ParseArgs | Select-String "startup.ps1"
$Arguments -match "startup.ps1 (?<content>.*)`"" | Out-Null
$Arguments = $matches['content']

Start-Process "CMD" -ArgumentList "/C powershell -Version 5.0 -noexit -executionpolicy Bypass -windowstyle maximized -command `"pwsh -command `"Set-Location C:\; Set-Location `'$dir`'; .\swarm.ps1 $arguments`"`"" -Verb RunAs