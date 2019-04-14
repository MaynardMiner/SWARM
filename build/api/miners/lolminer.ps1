
function Get-StatsLolminer {
    $Message = "/summary"
    $Request = Get-HTTP -Server $Server -Port $port -Message $Message
    if ($request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red; break }
        $global:RAW = [Double]$Data.Session.Performance_Summary        
        $global:GPUKHS += [Double]$Data.Session.Performance_Summary / 1000
        Write-MinerData2;
        $Hash = $Data.GPUs.Performance
        try { 
            for ($i = 0; $i -lt $Devices.Count; $i++) { 
                $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 
            } 
        }
        catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red };
        $global:MinerACC += [Double]$Data.Session.Accepted
        $global:MinerREJ += [Double]$Data.Session.Submitted - [Double]$Data.Session.Accepted
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    elseif (Test-Path ".\logs\$MinerType.log") {
        Write-Host "Miner API failed- Attempting to get hashrate through logs." -ForegroundColor Yellow
        Write-Host "Will only pull total hashrate in this manner." -ForegroundColor Yellow
        $MinerLog = Get-Content ".\logs\$MinerType.log" | Select-String "Average Speed " | Select-Object -Last 1
        $Speed = $MinerLog -split "Total: " | Select-Object -Last 1
        $Speed = $Speed -split "sol/s" | Select-Object -First 1
        if ($Speed) {
            $global:RAW += [Double]$Speed 
            $global:GPUKHS += [Double]$Speed / 1000
            Write-MinerData2;
        }
    }
    else { Set-APIFailure }
}