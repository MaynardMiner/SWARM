function Global:Get-Watts {
    if (-not $(vars).Watts) { $(vars).Watts = Get-Content ".\config\power\power.json" | ConvertFrom-Json }
    if($(arg).kwh -ne "") {
        $global:WattHour = $(arg).kwh
    } else { $global:WattHour = $(vars).Watts.KWh.$((Get-Date | Select-Object hour).Hour) }
}

function Global:Get-Pricing {
    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    try {
        log "SWARM Is Building The Database. Auto-Coin Switching: $($(arg).Auto_Coin)" -foreground "yellow"
        $(vars).Rates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=BTC" -UseBasicParsing | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates | Select-Object "$($(arg).Currency)"
        $(vars).WattEx = [Double](((1 / $(vars).Rates.$($(arg).Currency)) * $global:WattHour))
    }
    catch {
        log "WARNING: Coinbase Unreachable. " -ForeGroundColor Yellow
    }
}

function Global:Get-TimeCheck {
    if (Test-Path ".\build\data\system.txt") { [DateTime]$Start = "$(Get-Content ".\build\data\system.txt")" }
    $Day = [math]::Round(((Get-Date) - $Start).TotalSeconds)
    if($Day -ge 86400) {
        Rename-Item -Path ".\build\data\data.txt" -NewName "data.ps1" -Force | Out-Null
        . .\build\data\data.ps1
        Global:Get-DebugParams
        $(vars).options = 1
    }
}

function Global:Clear-Timeouts {
    if ($(vars).TimeoutTimer.Elapsed.TotalSeconds -gt $(vars).TimeoutTime -and $(arg).Timeout -ne 0) {
        log "Clearing Timeouts" -ForegroundColor Magenta; 
        if (Test-Path ".\timeout") { 
            Remove-Item ".\timeout" -Recurse -Force
        }
        $(vars).TimeoutTimer.Restart()  
    }
}