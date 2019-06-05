function Global:start-log {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Number
    )
    #Start the log
    if (-not (Test-Path "logs")) {New-Item "logs" -ItemType "directory" | Out-Null; Start-Sleep -S 1}
    if (Test-Path ".\logs\*active*") {
        $OldActiveFile = Get-ChildItem ".\logs" -Force | Where BaseName -like "*active*"
        $OldActiveFile | ForEach-Object {
            $RenameActive = ".\logs\$($_.Name)" -replace ("-active", "")
            if (Test-Path $RenameActive) {Remove-Item $RenameActive -Force}
            Move-Item ".\logs\$($OldActiveFile.Name)" $RenameActive -force
        }
    }
    $global:logname = Join-Path $($(v).dir) "logs\miner$($Number)-active.log"
}
