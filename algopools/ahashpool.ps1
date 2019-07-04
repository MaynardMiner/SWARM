
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$ahashpool_Request = [PSCustomObject]@{ } 


if($(arg).xnsub -eq "Yes"){$X = "#xnsub"}

if ($Name -in $(arg).PoolName) {
    try { $ahashpool_Request = Invoke-RestMethod "https://www.ahashpool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($ahashpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }
  
    $ahashpool_Request |
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { $ahashpool_Request.$_.hashrate -gt 0 } | 
    Where-Object {
        $Algo = $ahashpool_Request.$_.name.ToLower();
        $local:ahashpool_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $ahashpool_Algorithm
    } |
    ForEach-Object {
        if ($(vars).Algorithm -contains $ahashpool_Algorithm -or $(arg).ASIC_ALGO -contains $ahashpool_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$ahashpool_Algorithm.exclusions -and $ahashpool_Algorithm -notin $(vars).BanHammer) {
                $ahashpool_Host = "$_.mine.ahashpool.com$X"
                $ahashpool_Port = $ahashpool_Request.$_.port
                $Fees = $ahashpool_Request.$_.fees
                $Divisor = (1000000 * $ahashpool_Request.$_.mbtc_mh_factor)
                $Workers = $ahashpool_Request.$_.Workers
                $StatPath = ".\stats\($Name)_$($ahashpool_Algorithm)_profit.txt"
                $Hashrate = $ahashpool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $StatAlgo = $ahashpool_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$ahashpool_Request.$_.estimate_last24h / $Divisor * (1 - ($ahashpool_Request.$_.fees / 100)))
                } 
                else {
                    $StatAlgo = $ahashpool_Algorithm -replace "`_","`-"
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$ahashpool_Request.$_.estimate_current / $Divisor * (1 - ($ahashpool_Request.$_.fees / 100)))
                }

                if (-not $(vars).Pool_Hashrates.$ahashpool_Algorithm) { $(vars).Pool_Hashrates.Add("$ahashpool_Algorithm", @{ })
                }
                if (-not $(vars).Pool_Hashrates.$ahashpool_Algorithm.$Name) { $(vars).Pool_Hashrates.$ahashpool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })
                }

                [PSCustomObject]@{
                    Symbol    = "$ahashpool_Algorithm-Algo"
                    Algorithm = $ahashpool_Algorithm
                    Price     = $Stat.$($(arg).Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $ahashpool_Host
                    Port      = $ahashpool_Port
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
