$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$blockpool_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try {$blockpool_Request = Invoke-RestMethod "http://blockmasters.co/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} 
    catch {Write-Warning "SWARM contacted ($Name) but there was no response."; return}
 
    if (($blockpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    } 

    Switch ($Location) {
        "US" {$Region = $null}
        default {$Region = "eu."}
    }
  
    $blockpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$blockpool_Request.$_.hashrate -gt 0} |  Where-Object {$Naming.$($blockpool_Request.$_.name)} | ForEach-Object {

        $blockpool_Algorithm = $blockpool_Request.$_.name.ToLower()

        if ($Algorithm -contains $blockpool_Algorithm -and $Bad_pools.$blockpool_Algorithm -notcontains $Name) {
            $blockpool_Host = "$($Region)blockmasters.co"
            $blockpool_Port = $blockpool_Request.$_.port
            $Divisor = (1000000 * $blockpool_Request.$_.mbtc_mh_factor)
            $Workers = $blockpool_Request.$_.Workers

            ## I am adding a 30.0% fee to blockmasters.
            ## This is deliberate. The Pools stats are always
            ## Heavily inflated. Even with a 30.0% fee applied,
            ## They still manage to be on top of list.

            ## Think about that- 30.0% fee. Still on top of list...

            $Fee = 30.0

            $Estimate = if ($Stat_Algo -eq "Day") {[Double]$blockpool_Request.$_.estimate_last24h * (1 - ($Fee / 100))}else {[Double]$blockpool_Request.$_.estimate_current * (1 - ($Fee / 100))}

            $Stat = Set-Stat -Name "$($Name)_$($blockpool_Algorithm)_profit" -Value ([Double]$Estimate / $Divisor)
            if ($Stat_Algo -eq "Day") {$CStat = $Stat.Live}else {$CStat = $Stat.$Stat_Algo}

            $Pass1 = "$($global:Wallets.Wallet1.Keys)";
            $User1 = "$($global:Wallets.Wallet1.BTC.address)";
            $Pass2 = "$($global:Wallets.Wallet2.Keys)";
            $User2 = "$($global:Wallets.Wallet2.BTC.address)";
            $Pass3 = "$($global:Wallets.Wallet3.Keys)";
            $User3 = "$($global:Wallets.Wallet3.BTC.address)";

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
                Symbol        = $blockpool_Algorithm
                Mining        = $blockpool_Algorithm
                Algorithm     = $blockpool_Algorithm
                Price         = $CStat
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $blockpool_Host
                Port          = $blockpool_Port
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
