$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$nlpool_Request = [PSCustomObject]@{ }

if($(arg).xnsub -eq "Yes"){$X = "#xnsub"}

if ($Name -in $(arg).PoolName) {
    try { $nlpool_Request = Invoke-RestMethod "https://nlpool.nl/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch { log "SWARM contacted ($Name) but there was no response."; return }
   
    if (($nlpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }

    $nlpool_Request.PSObject.Properties.Value | % { $_.estimate_current = [Decimal]$_.estimate_current }

    $nlpool_Request | 
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { $nlpool_Request.$_.hashrate -gt 0 } | 
    Where-Object { $nlpool_Request.$_.name -NE "sha256" } | 
    Where-Object { $($nlpool_Request.$_.estimate_current) -gt 0 } |
    Where-Object {
        $Algo = $nlpool_Request.$_.name.ToLower();
        $local:nlpoolAlgo_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $nlpoolAlgo_Algorithm
    } |
    ForEach-Object {
        if ($(vars).Algorithm -contains $nlpoolAlgo_Algorithm -or $(arg).ASIC_ALGO -contains $nlpoolAlgo_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$nlpoolAlgo_Algorithm.exclusions -and $nlpoolAlgo_Algorithm -notin $(vars).BanHammer) {
                $nlpoolAlgo_Host = "mine.nlpool.nl$X"
                $nlpoolAlgo_Port = $nlpool_Request.$_.port
                ## btc - 8 bit estimates mh
                ## check to see for yiimp bug:
                if($nlpool_Request.$_.actual_last24h -gt 0) { $Divisor = (1000000 * $nlpool_Request.$_.mbtc_mh_factor)} 
                else {
                    ## returns are not actually mbtc/day - Flaw with yiimp calculation:
                    $Divisor = ( 1000000 * ($nlpool_Request.$_.mbtc_mh_factor/2) )
                }
                $StatPath = ".\stats\($Name)_$($nlpoolAlgo_Algorithm)_profit.txt"
                $Hashrate = $nlpool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $StatAlgo = $nlpoolAlgo_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -Hashrate $Hashrate -Value ( [Double]$nlpool_Request.$_.estimate_last24h / $Divisor * (1 - ($nlpool_Request.$_.fees / 100)))
                } 
                else {
                    $StatAlgo = $nlpoolAlgo_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -Hashrate $HashRates -Value ( [Double]$nlpool_Request.$_.estimate_current / $Divisor * (1 - ($nlpool_Request.$_.fees / 100)))
                }

                if (-not $(vars).Pool_Hashrates.$nlpoolAlgo_Algorithm) { $(vars).Pool_Hashrates.Add("$nlpoolAlgo_Algorithm", @{ })
                }
                if (-not $(vars).Pool_Hashrates.$nlpoolAlgo_Algorithm.$Name) { $(vars).Pool_Hashrates.$nlpoolAlgo_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })
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
                    Symbol    = "$nlpoolAlgo_Algorithm-Algo"
                    Algorithm = $nlpoolAlgo_Algorithm
                    Price     = $Stat.$($(arg).Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $nlpoolAlgo_Host
                    Port      = $nlpoolAlgo_Port
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
