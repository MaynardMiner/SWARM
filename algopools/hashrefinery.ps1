$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Hashrefinery_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try { $Hashrefinery_Request = Invoke-RestMethod "http://pool.hashrefinery.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Warning "SWARM contacted ($Name) but there was no response."; return }

    if (($Hashrefinery_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }  
   
    $Hashrefinery_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $Hashrefinery_Request.$_.hashrate -gt 0 } | Where-Object { $Naming.$($Hashrefinery_Request.$_.name) } | ForEach-Object {
   
        $Hashrefinery_Algorithm = $Hashrefinery_Request.$_.name.ToLower()

        if ($Algorithm -contains $Hashrefinery_Algorithm -or $ASIC_ALGO -contains $Hashrefinery_Algorithm) {
            if ($Bad_pools.$Hashrefinery_Algorithm -notcontains $Name) {
                $Hashrefinery_Host = "$_.us.hashrefinery.com"
                $Hashrefinery_Port = $Hashrefinery_Request.$_.port
                $Divisor = (1000000 * $Hashrefinery_Request.$_.mbtc_mh_factor)
                $Fees = $Hashrefinery_Request.$_.fees
                $Workers = $Hashrefinery_Request.$_.Workers
                $Estimate = if ($Stat_Algo -eq "Day") { [Double]$Hashrefinery_Request.$_.estimate_last24h }else { [Double]$Hashrefinery_Request.$_.estimate_current }

                $Stat = Set-Stat -Name "$($Name)_$($Hashrefinery_Algorithm)_profit" -Value ([Double]$Estimate / $Divisor * (1 - ($Hashrefinery_Request.$_.fees / 100)))
                if ($Stat_Algo -eq "Day") { $CStat = $Stat.Live }else { $CStat = $Stat.$Stat_Algo }
        
                [PSCustomObject]@{            
                    Priority      = $Priorities.Pool_Priorities.$Name
                    Symbol        = $Hashrefinery_Algorithm
                    Mining        = $Hashrefinery_Algorithm
                    Algorithm     = $Hashrefinery_Algorithm
                    Price         = $CStat
                    StablePrice   = $Stat.Week
                    MarginOfError = $Stat.Fluctuation
                    Protocol      = "stratum+tcp"
                    Host          = $Hashrefinery_Host
                    Port          = $Hashrefinery_Port
                    User1         = $global:Wallets.Wallet1.BTC.address
                    User2         = $global:Wallets.Wallet2.BTC.address
                    User3         = $global:Wallets.Wallet3.BTC.address
                    CPUser        = $global:Wallets.Wallet1.BTC.address
                    CPUPass       = "c=$($global:Wallets.Wallet1.keys),id=$Rigname1"
                    Pass1         = "c=$($global:Wallets.Wallet1.keys),id=$Rigname1"
                    Pass2         = "c=$($global:Wallets.Wallet2.keys),id=$Rigname2"
                    Pass3         = "c=$($global:Wallets.Wallet3.keys),id=$Rigname3"
                    Location      = $Location
                    SSL           = $false
                }
            }
        }
    }
}
    
