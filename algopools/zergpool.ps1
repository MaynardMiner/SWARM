$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Zergpool_Request = [PSCustomObject]@{ } 

if($(arg).xnsub -eq "Yes"){$X = "#xnsub"} 
 
if ($Name -in $(arg).PoolName) {
    try { $Zergpool_Request = Invoke-RestMethod "http://api.zergpool.com:8080/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Global:Write-Log "SWARM contacted ($Name) but there was no response."; return }
  
    if (($Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Global:Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    } 
     
    $Zergpool_Request | 
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { $Zergpool_Request.$_.hashrate -gt 0 } | 
    Where-Object {
        $Algo = $Zergpool_Request.$_.name.ToLower();
        $local:Zergpool_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $Zergpool_Algorithm
    } |
    ForEach-Object {  
        if ($(vars).Algorithm -contains $Zergpool_Algorithm -or $(arg).ASIC_ALGO -contains $Zergpool_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$Zergpool_Algorithm.exclusions -and $Zergpool_Algorithm -notin $(vars).BanHammer) {
                $Zergpool_Port = $Zergpool_Request.$_.port
                $Zergpool_Host = "$($Zergpool_Request.$_.name.ToLower()).mine.zergpool.com$X"
                $Divisor = (1000000 * $Zergpool_Request.$_.mbtc_mh_factor)
                $(vars).divisortable.zergpool.Add($Zergpool_Algorithm, $Zergpool_Request.$_.mbtc_mh_factor)
                $Fees = $Zergpool_Request.$_.fees
                $(vars).FeeTable.zergpool.Add($Zergpool_Algorithm, $Zergpool_Request.$_.fees)
                $StatPath = ".\stats\($Name)_$($Zergpool_Algorithm)_profit.txt"
                $Hashrate = $Zergpool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $StatAlgo = $Zergpool_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$Zergpool_Request.$_.estimate_last24h / $Divisor * (1 - ($Zergpool_Request.$_.fees / 100)))
                } 
                else {
                    $StatAlgo = $Zergpool_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$Zergpool_Request.$_.estimate_current / $Divisor * (1 - ($Zergpool_Request.$_.fees / 100)))
                }

                if (-not $(vars).Pool_Hashrates.$Zergpool_Algorithm) { $(vars).Pool_Hashrates.Add("$Zergpool_Algorithm", @{ })
                }
                if (-not $(vars).Pool_Hashrates.$Zergpool_Algorithm.$Name) { $(vars).Pool_Hashrates.$Zergpool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })
                }

                $Pass1 = $global:Wallets.Wallet1.Keys
                $User1 = $global:Wallets.Wallet1.$($(arg).Passwordcurrency1).address
                $Pass2 = $global:Wallets.Wallet2.Keys
                $User2 = $global:Wallets.Wallet2.$($(arg).Passwordcurrency2).address
                $Pass3 = $global:Wallets.Wallet3.Keys
                $User3 = $global:Wallets.Wallet3.$($(arg).Passwordcurrency3).address
                
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
                    Symbol    = "$Zergpool_Algorithm-Algo"
                    Algorithm = $Zergpool_Algorithm
                    Price     = $Stat.$($(arg).Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $Zergpool_Host
                    Port      = $Zergpool_Port
                    User1     = $User1
                    User2     = $User2
                    User3     = $User3
                    Pass1     = "c=$Pass1,id=$($(arg).RigName1)"
                    Pass2     = "c=$Pass2,id=$($(arg).RigName2)"
                    Pass3     = "c=$Pass3,id=$($(arg).RigName3)"
                }
            }
        }
    }
}
