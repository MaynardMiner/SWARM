$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Hashrefinery_Request = [PSCustomObject]@{ } 

if($(arg).xnsub -eq "Yes"){$X = "#xnsub"}
 
if ($Name -in $(arg).PoolName) {
    try { $Hashrefinery_Request = Invoke-RestMethod "http://pool.hashrefinery.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { log "SWARM contacted ($Name) but there was no response."; return }

    if (($Hashrefinery_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }  
   
    $Hashrefinery_Request | 
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { $Hashrefinery_Request.$_.hashrate -gt 0 } | 
    Where-Object {
        $Algo = $Hashrefinery_Request.$_.name.ToLower();
        $local:Hashrefinery_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $Hashrefinery_Algorithm
    } |
    ForEach-Object {
        if ($(vars).Algorithm -contains $Hashrefinery_Algorithm -or $(arg).ASIC_ALGO -contains $Hashrefinery_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$Hashrefinery_Algorithm.exclusions -and $Hashrefinery_Algorithm -notin $(vars).BanHammer) {
                $Hashrefinery_Host = "$_.us.hashrefinery.com$X"
                $Hashrefinery_Port = $Hashrefinery_Request.$_.port
                $Divisor = (1000000 * $Hashrefinery_Request.$_.mbtc_mh_factor)
                $Fees = $Hashrefinery_Request.$_.fees
                $Workers = $Hashrefinery_Request.$_.Workers
                $StatPath = ".\stats\($Name)_$($Hashrefinery_Algorithm)_profit.txt"
                $Hashrate = $Hashrefinery_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $StatAlgo = $Hashrefinery_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$Hashrefinery_Request.$_.estimate_last24h / $Divisor * (1 - ($Hashrefinery_Request.$_.fees / 100)))
                } 
                else {
                    $StatAlgo = $Hashrefinery_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$Hashrefinery_Request.$_.estimate_current / $Divisor * (1 - ($Hashrefinery_Request.$_.fees / 100)))
                }

                if (-not $(vars).Pool_Hashrates.$Hashrefinery_Algorithm) { $(vars).Pool_Hashrates.Add("$Hashrefinery_Algorithm", @{ })
                }
                if (-not $(vars).Pool_Hashrates.$Hashrefinery_Algorithm.$Name) { $(vars).Pool_Hashrates.$Hashrefinery_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })
                }
        
                [PSCustomObject]@{            
                    Symbol    = "$Hashrefinery_Algorithm-Algo"
                    Algorithm = $Hashrefinery_Algorithm
                    Price     = $Stat.$($(arg).Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $Hashrefinery_Host
                    Port      = $Hashrefinery_Port
                    User1     = $global:Wallets.Wallet1.$($(arg).Passwordcurrency1).address
                    User2     = $global:Wallets.Wallet2.$($(arg).Passwordcurrency2).address
                    User3     = $global:Wallets.Wallet3.$($(arg).Passwordcurrency3).address
                    Pass1     = "c=$($global:Wallets.Wallet1.keys),id=$($(arg).RigName1)"
                    Pass2     = "c=$($global:Wallets.Wallet2.keys),id=$($(arg).RigName2)"
                    Pass3     = "c=$($global:Wallets.Wallet3.keys),id=$($(arg).RigName3)"
                }
            }
        }
    }
}
    
