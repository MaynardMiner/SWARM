$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Whalesburg_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
 
if ($Poolname -eq $Name) {
    try {$Whalesburg_Request = Invoke-RestMethod "https://payouts.whalesburg.com/profitabilities/share_price" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} 
    catch {Write-Warning "SWARM contacted ($Name) but there was no response."; return}
  
    if (-not $Whalesburg_Request.mh_per_second_price) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty.";
        return
    }

    try {$ETHExchangeRate = Invoke-WebRequest "https://min-api.cryptocompare.com/data/pricemulti?fsyms=ETH&tsyms=BTC" -UseBasicParsing | ConvertFrom-Json | Select-Object -ExpandProperty "ETH" | Select-Object -ExpandProperty "BTC"}
    catch {Write-Warning "SWARM failed to get ETH Pricing for $Name"; return}

    $Whalesburg_Algorithm = "ethash"
  
    if ($Algorithm -eq $Whalesburg_Algorithm) {
        $Whalesburg_Port = 8082
        $Whalesburg_Host = "eu1.whalesburg.com"
        ## add fee to compare to nicehash (Still trying to understand PPS+)
        $Prorate = 2
        ## btc/mhs/day
        $Estimate = ((([Double]$Whalesburg_Request.mh_per_second_price * 86400))) * $ETHExchangeRate

        $Stat = Set-Stat -Name "$($Name)_$($Whalesburg_Algorithm)_profit" -Value ([Double]$Estimate * (1 - ($Prorate / 100)))

        [PSCustomObject]@{
            Priority      = $Priorities.Pool_Priorities.$Name
            Symbol        = $Whalesburg_Algorithm
            Mining        = $Whalesburg_Algorithm
            Algorithm     = $Whalesburg_Algorithm
            Price         = $Stat.$Stat_Algo
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol      = "stratum+ssl"
            Host          = $Whalesburg_Host
            Port          = $Whalesburg_Port
            User1         = $ETH
            User2         = $ETH
            User3         = $ETH
            CPUser        = $ETH
            Worker        = "$Worker"
            Location      = $Location
            SSL           = $false
        }
    }
}
