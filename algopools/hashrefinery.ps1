$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Hashrefinery_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if($global:Config.Params.xnsub -eq "Yes"){$X = "#xnsub"}
 
if ($Name -in $global:Config.Params.PoolName) {
    try { $Hashrefinery_Request = Invoke-RestMethod "http://pool.hashrefinery.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Log "SWARM contacted ($Name) but there was no response."; return }

    if (($Hashrefinery_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
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
        if ($Algorithm -contains $Hashrefinery_Algorithm -or $global:Config.Params.ASIC_ALGO -contains $Hashrefinery_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$Hashrefinery_Algorithm.exclusions -and $Hashrefinery_Algorithm -notin $Global:banhammer) {
                $Hashrefinery_Host = "$_.us.hashrefinery.com$X"
                $Hashrefinery_Port = $Hashrefinery_Request.$_.port
                $Divisor = (1000000 * $Hashrefinery_Request.$_.mbtc_mh_factor)
                $Fees = $Hashrefinery_Request.$_.fees
                $Workers = $Hashrefinery_Request.$_.Workers
                $StatPath = ".\stats\($Name)_$($Hashrefinery_Algorithm)_profit.txt"
                $Hashrate = $Hashrefinery_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $StatAlgo = $Hashrefinery_Algorithm -replace "`_","`-"
                    $Stat = Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$Hashrefinery_Request.$_.estimate_last24h / $Divisor * (1 - ($Hashrefinery_Request.$_.fees / 100)))
                } 
                else {
                    $StatAlgo = $Hashrefinery_Algorithm -replace "`_","`-"
                    $Stat = Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( [Double]$Hashrefinery_Request.$_.estimate_current / $Divisor * (1 - ($Hashrefinery_Request.$_.fees / 100)))
                }

                if (-not $global:Pool_Hashrates.$Hashrefinery_Algorithm) { $global:Pool_Hashrates.Add("$Hashrefinery_Algorithm", @{ })
                }
                if (-not $global:Pool_Hashrates.$Hashrefinery_Algorithm.$Name) { $global:Pool_Hashrates.$Hashrefinery_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" })
                }
        
                [PSCustomObject]@{            
                    Priority  = $Priorities.Pool_Priorities.$Name
                    Symbol    = "$Hashrefinery_Algorithm-Algo"
                    Mining    = $Hashrefinery_Algorithm
                    Algorithm = $Hashrefinery_Algorithm
                    Price     = $Stat.$($global:Config.Params.Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $Hashrefinery_Host
                    Port      = $Hashrefinery_Port
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
    
