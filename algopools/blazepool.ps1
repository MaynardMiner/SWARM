
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$blazepool_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if($global:Config.Params.xnsub -eq "Yes"){$X = "#xnsub"}
 
if ($Name -in $global:Config.Params.PoolName) {
    try { $blazepool_Request = Invoke-RestMethod "http://api.blazepool.com/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($blazepool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }   
  
    $blazepool_Request | 
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { $blazepool_Request.$_.hashrate -gt 0 } | 
    Where-Object { $global:Exclusions.$($blazepool_Request.$_.name) } |
    ForEach-Object {

        $blazepool_Algorithm = $blazepool_Request.$_.name.ToLower()

        if ($Algorithm -contains $blazepool_Algorithm -or $global:Config.Params.ASIC_ALGO -contains $blazepool_Algorithm) {
            if ($Name -notin $global:Exclusions.$blazepool_Algorithm.exclusions -and $blazepool_Algorithm -notin $Global:banhammer) {
                $blazepool_Host = "$_.mine.blazepool.com$X"
                $blazepool_Port = $blazepool_Request.$_.port
                $Divisor = (1000000 * $blazepool_Request.$_.mbtc_mh_factor)
                $Fees = $blazepool_Request.$_.fees
                $Workers = $blazepool_Request.$_.Workers
                $StatPath = ".\stats\($Name)_$($blazepool_Algorithm)_profit.txt"
                $Hashrate = $blazepool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$blazepool_Request.$_.estimate_last24h / $Divisor * (1 - ($blazepool_Request.$_.fees / 100)))
                } 
                else {
                    $Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$blazepool_Request.$_.estimate_current / $Divisor * (1 - ($blazepool_Request.$_.fees / 100)))
                }

                if (-not $global:Pool_Hashrates.$blazepool_Algorithm) { $global:Pool_Hashrates.Add("$blazepool_Algorithm", @{ })
                }
                if (-not $global:Pool_Hashrates.$blazepool_Algorithm.$Name) { $global:Pool_Hashrates.$blazepool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })
                }
    
                [PSCustomObject]@{
                    Priority  = $Priorities.Pool_Priorities.$Name
                    Symbol    = "$blazepool_Algorithm-Algo"
                    Mining    = $blazepool_Algorithm
                    Algorithm = $blazepool_Algorithm
                    Price     = $Stat.$($global:Config.Params.Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $blazepool_Host
                    Port      = $blazepool_Port
                    User1     = $global:Wallets.Wallet1.$($global:Config.Params.Passwordcurrency1).address
                    User2     = $global:Wallets.Wallet2.$($global:Config.Params.Passwordcurrency2).address
                    User3     = $global:Wallets.Wallet3.$($global:Config.Params.Passwordcurrency3).address
                    CPUser    = $global:Wallets.Wallet1.$($global:Config.Params.Passwordcurrency1).address   
                    CPUPass    = $global:Wallets.Wallet1.$($global:Config.Params.Passwordcurrency1).address                                     
                    Pass1     = "c=$($global:Wallets.Wallet1.keys),id=$($global:Config.Params.RigName1)"
                    Pass2     = "c=$($global:Wallets.Wallet2.keys),id=$($global:Config.Params.RigName2)"
                    Pass3     = "c=$($global:Wallets.Wallet3.keys),id=$($global:Config.Params.RigName3)"
                    Location  = $global:Config.Params.Location
                    SSL       = $false
                }
            }
        }
    }
}