
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$ahashpool_Request = [PSCustomObject]@{ } 


if($global:Config.Params.xnsub -eq "Yes"){$X = "#xnsub"}

if ($Name -in $global:Config.Params.PoolName) {
    try { $ahashpool_Request = Invoke-RestMethod "https://www.ahashpool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Global:Write-Log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($ahashpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Global:Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
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
        if ($global:Algorithm -contains $ahashpool_Algorithm -or $global:Config.Params.ASIC_ALGO -contains $ahashpool_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$ahashpool_Algorithm.exclusions -and $ahashpool_Algorithm -notin $Global:banhammer) {
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

                if (-not $global:Pool_Hashrates.$ahashpool_Algorithm) { $global:Pool_Hashrates.Add("$ahashpool_Algorithm", @{ })
                }
                if (-not $global:Pool_Hashrates.$ahashpool_Algorithm.$Name) { $global:Pool_Hashrates.$ahashpool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })
                }

                [PSCustomObject]@{
                    Symbol    = "$ahashpool_Algorithm-Algo"
                    Algorithm = $ahashpool_Algorithm
                    Price     = $Stat.$($global:Config.Params.Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $ahashpool_Host
                    Port      = $ahashpool_Port
                    User1     = $global:Wallets.Wallet1.$($global:Config.Params.Passwordcurrency1).address
                    User2     = $global:Wallets.Wallet2.$($global:Config.Params.Passwordcurrency2).address
                    User3     = $global:Wallets.Wallet3.$($global:Config.Params.Passwordcurrency3).address
                    Pass1     = "c=$($global:Wallets.Wallet1.keys),id=$($global:Config.Params.RigName1)"
                    Pass2     = "c=$($global:Wallets.Wallet2.keys),id=$($global:Config.Params.RigName2)"
                    Pass3     = "c=$($global:Wallets.Wallet3.keys),id=$($global:Config.Params.RigName3)"
                }
            }
        }
    }
}
