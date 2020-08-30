## Note on whalesburg.
## This pool is supposed to be a profit switching pool.
## I have never seen it switch.
## SWARM does not perform the switching, the pool does.
## Also,

## Miners are really weird with this pool. Some miners work
## Some do not. Some work in linux fine, other work in windows
## fine. I don't know the difference this pool causes in comparision
## to nicehash, but it seems to cause weird bugs in miners.
    
. .\build\powershell\global\modules.ps1
. .\build\powershell\global\classes.ps1

if ($(arg).PoolName -eq $Name) {
    $Whalesburg_Request = [PSCustomObject]@{ } 
 
    try { $Whalesburg_Request = Invoke-RestMethod "https://payouts.whalesburg.com/profitabilities/share_pric" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { 
        return "WARNING: SWARM contact $($Name) but there was no response"
    }
    try { $Whalesburg_Stats = Invoke-RestMethod "https://stats.whalesburg.com/current_stats" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { 
        return "WARNING: SWARM contacted ($Name) but there was no response." 
    }

    if (!$Whalesburg_Request.mh_per_second_price -or !$Whalesburg_Stats.eth) { 
        return "WARNING: SWARM contacted ($Name) but ($Name) the response was empty.";
    }
    try { $(vars).ETH_exchange = Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=ETH&tsyms=BTC" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch { return "WARNING: SWARM failed to get ETH Pricing for $Name"; }

    $(vars).ETH_exchange = $(vars).ETH_exchange.ETH.BTC

    $Whalesburg_Algorithm = "ethash"
  
    if ($(vars).Algorithm -contains $Whalesburg_Algorithm) {
        $Whalesburg_Port = "8082"
        $Whalesburg_Host = "eu1.whalesburg.com"
        ## add fee based on reward system. (they say its bonus, but actually fee)
        $Prorate = 2;
        ## btc/mhs/day
        $Estimate = ((([Double]$Whalesburg_Request.mh_per_second_price * 86400))) * $(vars).ETH_exchange;
        $Value = [convert]::ToDecimal($Estimate * (1 - ($Prorate / 100)));
        $Hashrate = [convert]::ToDecimal($Whalesburg_Stats.eth.current_hashrate);
        if (-not $Global:Config.vars.Pool_HashRates.$Name) {
            $Global:Config.vars.Pool_HashRates.Add("$Name", @{})
        }
        elseif (-not $Global:Config.vars.Pool_HashRates.$Name.$Whalesburg_Algorithm) {
            $Global:Config.vars.Pool_HashRates.$NameAdd("$Whalesburg_Algorithm", @{
                    Hashrate = "$Hashrate"
                    Percent  = ""
                })
        }

        $Stat = [Pool_Stat]::New("$($Name)_$($Whalesburg_Algorithm)", $Value, $hashrate, -1, $false)

        $Level = $Stat.$($(arg).Stat_Algo)
        $previous = $Stat.Day_MA

        [Pool]::New(
            ## Symbol
            "$Whalesburg_Algorithm-Algo",
            ## Algorithm
            "$Whalesburg_Algorithm",
            ## Level
            $Level,
            ## Stratum
            "stratum+tcp",
            ## Pool_Host
            $Whalesburg_Host,
            ## Pool_Port
            $Whalesburg_Port,
            ## User1
            $(arg).ETH,
            ## User2
            $(arg).ETH,
            ## User3
            $(arg).ETH,
            ## Worker
            "$($(arg).Worker)",
            ## Previous
            $previous
        )
    }
}
