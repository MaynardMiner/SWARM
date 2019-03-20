function Get-StatsSgminer {
    $global:HS = "hs"
    $Message = $null; $Message = @{command = "summary+devs"; parameter = ""} | ConvertTo-Json -Compress
    $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message $Message
    if ($Request) {
        $Tryother = $false
        try {$Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop}catch {$Tryother = $true}
        if ($Tryother -eq $true) {
            try {
                $Request = $Request.Substring($Request.IndexOf("{"), $Request.LastIndexOf("}") - $Request.IndexOf("{") + 1) -replace " ", "_"
                $Data = $Request | ConvertFrom-Json -ErrorAction Stop
            }
            catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
        }
        $summary = $Data.summary.summary
        $threads = $Data.devs.devs
        $Hash = $Null; $Sum = $Null;
        if ($summary.'KHS_5s' -gt 0) {$Sum = $summary.'KHS_5s'; $sgkey = 'KHS_5s'}
        elseif ($summary.'KHS 5s' -gt 0) {$Sum = $summary.'KHS 5s'; $sgkey = 'KHS 5s'}
        elseif ($summary.'KHS_30s' -gt 0) {$Sum = $Summary.'KHS_30s'; $sgkey = 'KHS_30s'}
        elseif ($summary.'KHS 30s' -gt 0) {$sum = $summary.'KHS 30s'; $sgkey = 'KHS 30s'}
        $Hash = $threads.$sgkey
        $global:BRAW += [Double]$Sum * 1000
        $global:BRAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        Write-MinerData2;
        $global:BKHS += $Sum
        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i}}catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
        $summary.Rejected | Foreach {$global:BMinerREJ += $_}
        $summary.Accepted | Foreach {$global:BMinerACC += $_}    
        $summary.Rejected | Foreach {$global:BREJ += $_}
        $summary.Accepted | Foreach {$global:BACC += $_}
        $global:BALGO += "$MinerALgo"
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
    }
    else {Set-APIFailure; break}
}