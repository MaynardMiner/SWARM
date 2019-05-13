## Note on whalesburg.
## This pool is supposed to be a profit switching pool.
## I have never seen it switch.
## SWARM does not perform the switching, the pool does.
## Also,

## Miners are really weird with this pool. Some miners work
## Some do not. Some work in linux fine, other work in windows
## fine. I don't know the difference this pool causes in comparision
## to nicehash, but it seems to cause weird bugs in miners.

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Whalesburg_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if($global:Config.Params.xnsub -eq "Yes"){$X = "#xnsub"} 
 
if ($global:Config.Params.PoolName -eq $Name) {
    try {$Whalesburg_Request = Invoke-RestMethod "https://payouts.whalesburg.com/profitabilities/share_price" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} 
    catch {Write-Warning "SWARM contacted ($Name) but there was no response."; return}
  
    if (-not $Whalesburg_Request.mh_per_second_price) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty.";
        return
    }

    try {$ETHExchangeRate = Invoke-WebRequest "https://min-api.cryptocompare.com/data/pricemulti?fsyms=ETH&tsyms=BTC" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop | ConvertFrom-Json | Select-Object -ExpandProperty "ETH" | Select-Object -ExpandProperty "BTC"}
    catch {Write-Warning "SWARM failed to get ETH Pricing for $Name"; return}

    $Whalesburg_Algorithm = "ethash"
  
    if ($Algorithm -contains $Whalesburg_Algorithm -and $Bad_pools.$Whalesburg_Algorithm -notcontains $Name) {
        $Whalesburg_Port = "7777"
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
            Price         = $Stat.$($global:Config.Params.Stat_Algo)
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol      = "stratum+ssl"
            Host          = $Whalesburg_Host
            Port          = $Whalesburg_Port
            User1         = $global:Config.Params.ETH
            User2         = $global:Config.Params.ETH
            User3         = $global:Config.Params.ETH
            CPUser        = $global:Config.Params.ETH
            Worker        = "$($global:Config.Params.Worker)"
            Location      = $global:Config.Params.Location
            SSL           = $false
        }
    }
}
