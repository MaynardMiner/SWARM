function Get-Watts {
    if ($global:Watts) { $global:Watts | ConvertTo-Json | Out-File ".\config\power\power.json" }
    if (-not $Global:Watt) { $global:Watts = Get-Content ".\config\power\power.json" | ConvertFrom-Json }
    $global:WattHour = $(Get-Date | Select-Object hour).Hour
}

function Get-Pricing {
    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    try {
        Write-Log "SWARM Is Building The Database. Auto-Coin Switching: $($global:Config.Params.Auto_Coin)" -foreground "yellow"
        $global:Rates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=BTC" -UseBasicParsing | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates
        $global:Config.Params.Currency | Where-Object { $global:Rates.$_ } | ForEach-Object { $global:Rates | Add-Member $_ ([Double]$global:Rates.$_) -Force }
        $global:WattEX = [Double](((1 / $global:Rates.$($global:Config.Params.Currency)) * $global:Watts.KWh.$global:WattHour))
    }
    catch {
        write-Log "WARNING: Coinbase Unreachable. " -ForeGroundColor Yellow
    }
}

function Clear-Timeouts {
    if ($global:TimeoutTimer.Elapsed.TotalSeconds -gt $global:TimeoutTime -and $global:Config.Params.Timeout -ne 0) {
        write-Log "Clearing Timeouts" -ForegroundColor Magenta; 
        if (Test-Path ".\timeout") { 
            Remove-Item ".\timeout" -Recurse -Force
        }
        $global:TimeoutTimer.Restart()  
    }
}