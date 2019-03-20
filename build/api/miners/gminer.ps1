function Get-StatsGminer {
$global:HS = "hs"
$Request = $null; $Request = Get-HTTP -Server $server -Port $Port -Message "/stat" -Timeout 5
if ($Request) {
    try {$Data = $null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop}Catch {Write-Host "Failed To parse API" -ForegroundColor Red}
    $Data.devices.speed | % {$global:BRAW += [Double]$_}
    $Hash = $Null; $Hash = $Data.devices.speed
    Write-MinerData2;
    try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
    $Data.devices.accepted_shares | Select -First 1 | Foreach {$global:BMinerACC += $_}
    $Data.devices.rejected_shares | Select -First 1 | Foreach {$global:BMinerREJ += $_}
    $Data.devices.accepted_shares | Select -First 1 | Foreach {$global:BACC += $_}
    $Data.devices.rejected_shares | Select -First 1 | Foreach {$global:BREJ += $_}
    $Data.devices.speed | foreach {$global:BKHS += [Double]$_}
    $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
    $global:BALGO += "$MinerAlgo"
}
else {Set-APIFailure; break}
}