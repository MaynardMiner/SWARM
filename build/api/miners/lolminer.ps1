
function Get-StatsLolminer {
    $global:HS = "hs"
    $Message = "/summary"
    $request = $null; $Request = Get-HTTP -Server $Server -Port $port -Message $Message
    if ($request) {
        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
        $global:BRAW = [Double]$Data.Session.Performance_Summary
        Write-MinerData2;
        $Hash = $Data.GPUs.Performance
        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
        $global:BMinerACC += [Double]$Data.Session.Accepted
        $global:BMinerREJ += [Double]$Data.Session.Submitted - [Double]$Data.Session.Accepted
        $global:BACC += $Data.Session.Accepted
        $global:BREJ += [Double]$Data.Session.Submitted - [Double]$Data.Session.Accepted
        $global:BKHS += [Double]$Data.Session.Performance_Summary / 1000
        $global:BALGO += "$MinerAlgo"
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)          
    }
    else {Set-APIFailure; break}
}