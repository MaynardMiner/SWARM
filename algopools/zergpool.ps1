$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Zergpool_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
 
if ($Poolname -eq $Name) {
    try { $Zergpool_Request = Invoke-RestMethod "http://api.zergpool.com:8080/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Log "SWARM contacted ($Name) but there was no response."; return }
  
    if (($Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    } 
     
    $Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $Zergpool_Request.$_.hashrate -gt 0 } | Where-Object { $Naming.$($Zergpool_Request.$_.name) } | ForEach-Object {
    
        $Zergpool_Algorithm = $Zergpool_Request.$_.name.ToLower()
  
        if ($Algorithm -contains $Zergpool_Algorithm -or $ASIC_ALGO -contains $Zergpool_Algorithm) {
            if ($Bad_pools.$Zergpool_Algorithm -notcontains $Name) {
                $Zergpool_Port = $Zergpool_Request.$_.port
                $Zergpool_Host = "$($Zergpool_Algorithm).mine.zergpool.com"
                $Divisor = (1000000 * $Zergpool_Request.$_.mbtc_mh_factor)
                $Global:DivisorTable.zergpool.Add($Zergpool_Algorithm,$Zergpool_Request.$_.mbtc_mh_factor)
                $Fees = $Zergpool_Request.$_.fees
                $Global:FeeTable.zergpool.Add($Zergpool_Algorithm,$Zergpool_Request.$_.fees)
                $StatPath = ".\stats\($Name)_$($Zergpool_Algorithm)_profit.txt"
                $Hashrate = $Zergpool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $Stat = Set-Stat -Name "$($Name)_$($Zergpool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$Zergpool_Request.$_.estimate_last24h / $Divisor * (1 - ($Zergpool_Request.$_.fees / 100)))
                } 
                else {
                    $Stat = Set-Stat -Name "$($Name)_$($Zergpool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$Zergpool_Request.$_.estimate_current / $Divisor * (1 - ($Zergpool_Request.$_.fees / 100)))
                }

                if(-not $global:Pool_Hashrates.$Zergpool_Algorithm){$global:Pool_Hashrates.Add("$Zergpool_Algorithm",@{})}
                if(-not $global:Pool_Hashrates.$Zergpool_Algorithm.$Name){$global:Pool_Hashrates.$Zergpool_Algorithm.Add("$Name",@{HashRate = "$($Stat.HashRate)"; Percent = ""})}

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
                    Symbol        = "$Zergpool_Algorithm-Algo"
                    Mining        = $Zergpool_Algorithm
                    Algorithm     = $Zergpool_Algorithm
                    Price         = $Stat.$Stat_Algo
                    Protocol      = "stratum+tcp"
                    Host          = $Zergpool_Host
                    Port          = $Zergpool_Port
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
