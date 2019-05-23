
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$fairpool_Request = [PSCustomObject]@{ } 

if($global:Config.Params.xnsub -eq "Yes"){$X = "#xnsub"}
 
if ($Name -in $global:Config.Params.PoolName) {
    try { $fairpool_Request = Invoke-RestMethod "https://fairpool.pro/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($fairpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }

    Switch ($global:Config.Params.Location) {
        "US" { $Region = "us1.fairpool.pro" }
        default { $Region = "eu1.fairpool.pro" }
    }
  
    $fairpool_Request | 
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { $fairpool_Request.$_.hashrate -gt 0 } | 
    Where-Object {
        $Algo = $fairpool_Request.$_.name.ToLower();
        $local:fairpool_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $fairpool_Algorithm
    } |
    ForEach-Object {
        if ($Algorithm -contains $fairpool_Algorithm -or $global:Config.Params.ASIC_ALGO -contains $fairpool_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$fairpool_Algorithm.exclusions -and $fairpool_Algorithm -notin $Global:banhammer) {
                $fairpool_Host = "$region$X"
                $fairpool_Port = $fairpool_Request.$_.port
                $Divisor = (1000000 * $fairpool_Request.$_.mbtc_mh_factor)
                $Fees = $fairpool_Request.$_.fees
                $Workers = $fairpool_Request.$_.Workers
                $StatPath = ".\stats\($Name)_$($fairpool_Algorithm)_profit.txt"
                $Hashrate = $blockpool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $StatAlgo = $fairpool_Algorithm -replace "`_","`-"
                    $Stat = Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -Hashrate $Hashrate -Value ( [Double]$fairpool_Request.$_.estimate_last24h / $Divisor * (1 - ($fairpool_Request.$_.fees / 100)))
                } 
                else {
                    $StatAlgo = $fairpool_Algorithm -replace "`_","`-"
                    $Stat = Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -Hashrate $Hashrate -Value ( [Double]$fairpool_Request.$_.estimate_current / $Divisor * (1 - ($fairpool_Request.$_.fees / 100)))
                }

                if (-not $global:Pool_Hashrates.$fairpool_Algorithm) { $global:Pool_Hashrates.Add("$fairpool_Algorithm", @{ })
                }
                if (-not $global:Pool_Hashrates.$fairpool_Algorithm.$Name) { $global:Pool_Hashrates.$fairpool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })
                }
   
                [PSCustomObject]@{
                    Symbol    = "$fairpool_Algorithm-Algo"
                    Algorithm = $fairpool_Algorithm
                    Price     = $Stat.$($global:Config.Params.Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $fairpool_Host
                    Port      = $fairpool_Port
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
