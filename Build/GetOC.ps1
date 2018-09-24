Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
Get-Content ".\OC-Settings.txt"
exit