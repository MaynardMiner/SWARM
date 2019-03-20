
function Get-StatsXmrstakOPT {
    Write-Host "Miner $MinerType is xmrstak api"
    Write-Host "Miner Devices is $Devices"
    Write-Host "Note: XMR-STAK API sucks. You can't match threads to GPU." -ForegroundColor Yellow
    $global:BCPUHS = "hs"
    $Message = "/api.json"
    $Request = $Null
    $Request = Get-HTTP -Port $Port -Message $Message
    if ($Request) {
        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
        $Hash = $Data.Hashrate.Threads
        try {$Data.hashrate.total -split "," | % {if ($_ -ne "") {$global:BCPURAW = $_; $global:BCPUKHS = $_; $global:BCPUSUM = $_; break}}}catch {}
        $global:BCPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:CPUHashrates.$($GCount.$TypeS.$GPU) = $(if ($Hash.Count -eq 1) {[Double]$($Hash[0] | Select -first 1) / 1000}else {[Double]$($Hash[$i] | Select -First 1) / 1000})}
        $global:BMinerACC = 0
        $global:BMinerREJ = 0
        $global:BMinerACC += $Data.results.shares_good
        $global:BMinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:BCPUACC += $Data.results.shares_good
        $global:BCPUREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:BCPUUPTIME = $Data.connection.uptime
        $global:BCPUALGO = $MinerAlgo
    }
    else {Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $global:BCPURAW = 0; $global:BCPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
}