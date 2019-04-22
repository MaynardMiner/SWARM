$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$blockpool_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try { $blockpool_Request = Invoke-RestMethod "http://blockmasters.co/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Warning "SWARM contacted ($Name) but there was no response."; return }
 
    if (($blockpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    } 

    Switch ($Location) {
        "US" { $Region = $null }
        default { $Region = "eu." }
    }
  
    $blockpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $blockpool_Request.$_.hashrate -gt 0 } | Where-Object { $Naming.$($blockpool_Request.$_.name) } | ForEach-Object {

        $blockpool_Algorithm = $blockpool_Request.$_.name.ToLower()

        if ($Algorithm -contains $blockpool_Algorithm -or $ASIC_ALGO -contains $blockpool_Algorithm) {
            if ($Bad_pools.$blockpool_Algorithm -notcontains $Name) {
                $blockpool_Host = "$($Region)blockmasters.co"
                $blockpool_Port = $blockpool_Request.$_.port
                $Divisor = (1000000 * $blockpool_Request.$_.mbtc_mh_factor)
                $StatPath = ".\stats\($Name)_$($blockpool_Algorithm)_profit.txt"
                $Hashrate = $blockpool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $Stat = Set-Stat -Name "$($Name)_$($blockpool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$blockpool_Request.$_.estimate_last24h / $Divisor * (1 - ($blockpool_Request.$_.fees / 100)))
                } 
                else {
                    $Stat = Set-Stat -Name "$($Name)_$($blockpool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$blockpool_Request.$_.estimate_current / $Divisor * (1 - ($blockpool_Request.$_.fees / 100)))
                }

                if(-not $global:Pool_Hashrates.$blockpool_Algorithm){$global:Pool_Hashrates.Add("$blockpool_Algorithm",@{})}
                $global:Pool_Hashrates.$blockpool_Algorithm.Add("$Name","$($Stat.HashRate)")

                $Pass1 = $global:Wallets.Wallet1.Keys
                $User1 = $global:Wallets.Wallet1.$Passwordcurrency1.address
                $Pass2 = $global:Wallets.Wallet2.Keys
                $User2 = $global:Wallets.Wallet2.$Passwordcurrency2.address
                $Pass3 = $global:Wallets.Wallet3.Keys
                $User3 = $global:Wallets.Wallet3.$Passwordcurrency3.address
            
            if ($global:Wallets.AltWallet1.keys) {
                $global:Wallets.AltWallet1.Keys | ForEach-Object {
                    if ($global:Wallets.AltWallet1.$_.Pools -contains $Name) {
                        $Pass1 = $_;
                        $User1 = $global:Wallets.AltWallet1.$_.address;
                    }
                }
            }
            if ($global:Wallets.AltWallet2.keys) {
                $global:Wallets.AltWallet2.Keys | ForEach-Object {
                    if ($global:Wallets.AltWallet2.$_.Pools -contains $Name) {
                        $Pass2 = $_;
                        $User2 = $global:Wallets.AltWallet2.$_.address;
                    }
                }
            }
            if ($global:Wallets.AltWallet3.keys) {
                $global:Wallets.AltWallet3.Keys | ForEach-Object {
                    if ($global:Wallets.AltWallet3.$_.Pools -contains $Name) {
                        $Pass3 = $_;
                        $User3 = $global:Wallets.AltWallet3.$_.address;
                    }
                }
            }
                        
                [PSCustomObject]@{            
                    Priority      = $Priorities.Pool_Priorities.$Name
                    Symbol        = "$blockpool_Algorithm-Algo"
                    Mining        = $blockpool_Algorithm
                    Algorithm     = $blockpool_Algorithm
                    Price         = $Stat.$Stat_Algo
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
}
