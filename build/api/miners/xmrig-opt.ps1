
function Get-Statsxmrigopt {
    $global:BCPUHS = "hs"
    $Message = "/api.json"
    $Request = $Null
    $Request = Get-HTTP -Port $Port -Message $Message
    if ($Request) {
        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To gather summary" -ForegroundColor Red}
        $HashRate_Total = [Double]$Data.hashrate.total[0]
        if (-not $HashRate_Total) {$HashRate_Total = [Double]$Data.hashrate.total[1]} #fix
        if (-not $HashRate_Total) {$HashRate_Total = [Double]$Data.hashrate.total[2]} #fix
        $global:BCPURAW = $HashRate_Total
        Write-MinerData2
        Write-Host "Note: XMR-STAK/XMRig API is not great. You can't match threads to specific CPU." -ForegroundColor Yellow
        try {$Hash = for ($i = 0; $i -lt $Data.hashrate.threads.count; $i++) {$Data.Hashrate.threads[$i] | Select -First 1}}catch {}
        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:CPUHashrates.$GPU = ($Hash[$GPU] | Select -First 1) / 1000}}catch {Write-Host "Failed To parse threads" -ForegroundColor Red};
        $global:BCPUACC += $Data.results.shares_good
        $global:BCPUREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:BCPUUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        $global:BCPUALGO += "$MinerAlgo"
        try {$global:BCPUKHS += [Double]$HashRate_Total / 1000}catch {}
    }
    else {Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $global:BCPURAW = 0; $global:BCPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
}