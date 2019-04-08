$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Zpool_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
 
if ($Poolname -eq $Name) {
    try { $Zpool_Request = Invoke-RestMethod "http://www.zpool.ca/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Warning "SWARM contacted ($Name) but there was no response."; return }
  
    if (($Zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    } 
   
    Switch ($Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "sea" }
    }
  
    $Zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $Zpool_Request.$_.hashrate -gt 0 } | Where-Object { $Naming.$($Zpool_Request.$_.name) } | ForEach-Object {
    
        $Zpool_Algorithm = $Zpool_Request.$_.name.ToLower()
  
        if ($Algorithm -contains $Zpool_Algorithm -or $ASIC_ALGO -contains $Zpool_Algorithm) {
            if ($Bad_pools.$Zpool_Algorithm -notcontains $Name) {
                $Zpool_Port = $Zpool_Request.$_.port
                $Zpool_Host = "$($ZPool_Algorithm).$($region).mine.zpool.ca"
                $Divisor = (1000000 * $Zpool_Request.$_.mbtc_mh_factor)
                $Fees = $Zpool_Request.$_.fees
                $Workers = $Zpool_Request.$_.Workers
                $Estimate = if ($Stat_Algo -eq "Day") { [Double]$Zpool_Request.$_.estimate_last24h }else { [Double]$Zpool_Request.$_.estimate_current }

                ## ZPool fees are calculated differently, due to pool fee structure.
                $Cut = ConvertFrom-Fees $Fees $Workers $Estimate

                $Stat = Set-Stat -Name "$($Name)_$($Zpool_Algorithm)_profit" -Value ([Double]$Cut / $Divisor)
                if ($Stat_Algo -eq "Day") { $CStat = $Stat.Live }else { $CStat = $Stat.$Stat_Algo }
         
                $Pass1 = $global:Wallets.Wallet1.Keys
                $User1 = $global:Wallets.Wallet1.BTC.address
                $Pass2 = $global:Wallets.Wallet2.Keys
                $User2 = $global:Wallets.Wallet2.BTC.address
                $Pass3 = $global:Wallets.Wallet3.Keys
                $User3 = $global:Wallets.Wallet3.BTC.address

                $global:Wallets.AltWallet1.Keys | ForEach-Object {
                    if ($global:Wallets.AltWallet1.$_.Pools -contains $Name) {
                        $Pass1 = $_;
                        $User1 = $global:Wallets.AltWallet1.$_.address;
                    }
                }
                $global:Wallets.AltWallet2.Keys | ForEach-Object {
                    if ($global:Wallets.AltWallet2.$_.Pools -contains $Name) {
                        $Pass2 = $_;
                        $User2 = $global:Wallets.AltWallet2.$_.address;
                    }
                }
                $global:Wallets.AltWallet3.Keys | ForEach-Object {
                    if ($global:Wallets.AltWallet3.$_.Pools -contains $Name) {
                        $Pass3 = $_;
                        $User3 = $global:Wallets.AltWallet3.$_.address;
                    }
                }

                [PSCustomObject]@{
                    Priority      = $Priorities.Pool_Priorities.$Name
                    Symbol        = $Zpool_Algorithm
                    Mining        = $Zpool_Algorithm
                    Algorithm     = $Zpool_Algorithm
                    Price         = $CStat
                    StablePrice   = $Stat.Week
                    MarginOfError = $Stat.Fluctuation
                    Protocol      = "stratum+tcp"
                    Host          = $Zpool_Host
                    Port          = $Zpool_Port
                    User1         = $User1
                    User2         = $User2
                    User3         = $User3
                    CPUser        = $User1
                    CPUPass       = "c=$Pass1,id=$Rigname1"
                    Pass1         = "c=$Pass1,id=$Rigname1"
                    Pass2         = "c=$Pass2,id=$Rigname2"
                    Pass3         = "c=$Pass3,id=$Rigname3"
                    Location      = $Location
                    SSL           = $false
                }
            }
        }
    }
}
