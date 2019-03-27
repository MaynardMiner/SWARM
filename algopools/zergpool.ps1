$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Zergpool_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
 
if ($Poolname -eq $Name) {
    try {$Zergpool_Request = Invoke-RestMethod "http://api.zergpool.com:8080/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} 
    catch {Write-Warning "SWARM contacted ($Name) but there was no response."; return}
  
    if (($Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    } 
     
    $Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$Zergpool_Request.$_.hashrate -gt 0} |  Where-Object {$Naming.$($Zergpool_Request.$_.name)} | ForEach-Object {
    
        $Zergpool_Algorithm = $Zergpool_Request.$_.name.ToLower()
  
        if ($Algorithm -contains $Zergpool_Algorithm -and $Bad_pools.$Zergpool_Algorithm -notcontains $Name) {
            $Zergpool_Port = $Zergpool_Request.$_.port
            $Zergpool_Host = "$($Zergpool_Algorithm).mine.zergpool.com"
            $Divisor = (1000000 * $Zergpool_Request.$_.mbtc_mh_factor)
            $Fees = $Zergpool_Request.$_.fees
            $Workers = $Zergpool_Request.$_.Workers
            $Estimate = if ($Stat_Algo -eq "Day") {[Double]$Zergpool_Request.$_.estimate_last24h}else {[Double]$Zergpool_Request.$_.estimate_current}

            $Stat = Set-Stat -Name "$($Name)_$($Zergpool_Algorithm)_profit" -Value ([Double]$Estimate/$Divisor *(1-($Zergpool_Request.$_.fees/100)))
            if ($Stat_Algo -eq "Day") {$CStat = $Stat.Live}else {$CStat = $Stat.$Stat_Algo}
            

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
                Symbol        = $Zergpool_Algorithm
                Mining        = $Zergpool_Algorithm
                Algorithm     = $Zergpool_Algorithm
                Price         = $CStat
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $Zergpool_Host
                Port          = $Zergpool_Port
                User1         = $User1
                User2         = $User2
                User3         = $User3
                CPUser        = $User1
                CPUPass       = "c=$Pass1,ID=$Rigname1"
                Pass1         = "c=$Pass1,ID=$Rigname1"
                Pass2         = "c=$Pass2,ID=$Rigname2"
                Pass3         = "c=$Pass3,ID=$Rigname3"
                Location      = $Location
                SSL           = $false
            }
        }
    }
}
