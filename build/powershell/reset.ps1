Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))

Write-Host "Clearing All Previous Stored HiveOS Data"
if(test-path ".\build\txt"){Remove-Item ".\build\txt\*" -Force}
if(test-path ".\config\parameters\newarguments.json"){Remove-Item ".\config\parameters\newarguments.json" -Force}
if(test-Path ".\config\parameters\arguments.json"){Remove-Item ".\config\parameters\arguments.json" -Force}
Write-Host "All Data Is Removed!"