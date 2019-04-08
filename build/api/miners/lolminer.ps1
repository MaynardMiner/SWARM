
function Get-StatsLolminer {
    $global:HS = "hs"
    $Message = "/summary"
    $request = $null; $Request = Get-HTTP -Server $Server -Port $port -Message $Message
    if ($request) {
        try { $Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        $global:BRAW = [Double]$Data.Session.Performance_Summary
        Write-MinerData2;
        $Hash = $Data.GPUs.Performance
        try { for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 } }catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red };
        $global:BMinerACC += [Double]$Data.Session.Accepted
        $global:BMinerREJ += [Double]$Data.Session.Submitted - [Double]$Data.Session.Accepted
        $global:BACC += $Data.Session.Accepted
        $global:BREJ += [Double]$Data.Session.Submitted - [Double]$Data.Session.Accepted
        $global:BKHS += [Double]$Data.Session.Performance_Summary / 1000
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:BALGO.Add("Main", $global:BHiveAlgo) }
        else { $global:BALGO.Add($MinerType, $global:BHiveAlgo) }
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:TALGO.Add("Main", $MinerAlgo) }
        else { $global:TALGO.Add($MinerType, $MinerAlgo) }
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)          
    }
    elseif (Test-Path ".\logs\$MinerType.log") {
        Write-Host "Miner API failed- Attempting to get hashrate through logs." -ForegroundColor Yellow
        Write-Host "Will only pull total hashrate in this manner." -ForegroundColor Yellow
        $MinerLog = Get-Content ".\logs\$MinerType.log" | Select-String "Average Speed " | Select-Object -Last 1
        $Speed = $MinerLog -split "Total: " | Select-Object -Last 1
        $Speed = $Speed -split "sol/s" | Select-Object -First 1
        if ($Speed) {
            $global:BRAW += [Double]$Speed 
            $global:BKHS += [Double]$Speed / 1000
            Write-MinerData2;
        }
    }
    else { Set-APIFailure; break }
}