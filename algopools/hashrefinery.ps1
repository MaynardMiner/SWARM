$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Hashrefinery_Request = [PSCustomObject]@{ } 
$Meets_Threshold = $true

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
    Where-Object { [Double]$Hashrefinery_Request.$_.estimate_current -gt 0 } | 
    Where-Object {
        $Algo = $Hashrefinery_Request.$_.name.ToLower();
        $local:Hashrefinery_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $Hashrefinery_Algorithm
    } |
    ForEach-Object {
        if ($(vars).Algorithm -contains $Hashrefinery_Algorithm -or $(arg).ASIC_ALGO -contains $Hashrefinery_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$Hashrefinery_Algorithm.exclusions -and $Hashrefinery_Algorithm -notin $(vars).BanHammer) {

                $StatAlgo = $Hashrefinery_Algorithm -replace "`_", "`-"
                $StatPath = ".\stats\($Name)_$($StatAlgo)_profit.txt"
                if(Test-Path $StatPath) { $Estimate = [Double]$Hashrefinery_Request.$_.estimate_current }
                else { $Estimate = [Double]$Hashrefinery_Request.$_.estimate_last24h }

                if ($(arg).mode -eq "easy") {
                    if( $Hashrefinery_Request.$_.actual_last24h -eq 0 ){ $Meets_Threshold = $false } else {$Meets_Threshold = $True}
                    $Shuffle = Shuffle $Hashrefinery_Request.$_.estimate_current $Hashrefinery_Request.$_.actual_last24h
                } else {$Meets_Threshold = $true}

                $Hashrefinery_Host = "$_.us.hashrefinery.com$X"
                $Hashrefinery_Port = $Hashrefinery_Request.$_.port
                $Divisor = 1000000 * $Hashrefinery_Request.$_.mbtc_mh_factor
                $Hashrate = $Hashrefinery_Request.$_.hashrate

                $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( $Estimate / $Divisor * (1 - ($Hashrefinery_Request.$_.fees / 100))) -Shuffle $Shuffle
                if (-not $(vars).Pool_Hashrates.$Hashrefinery_Algorithm) { $(vars).Pool_Hashrates.Add("$Hashrefinery_Algorithm", @{ }) }
                if (-not $(vars).Pool_Hashrates.$Hashrefinery_Algorithm.$Name) { $(vars).Pool_Hashrates.$Hashrefinery_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" }) }

               $Level = $Stat.$($(arg).Stat_Algo)
                if($(arg).mode -eq "easy") {
                    $SmallestValue = 1E-20 
                    $Level = [Math]::Max($Level + ($Level * $Stat.Deviation), $SmallestValue)
                }

                [PSCustomObject]@{            
                    Symbol    = "$Hashrefinery_Algorithm-Algo"
                    Algorithm = $Hashrefinery_Algorithm
                    Price     = $Level
                    Protocol  = "stratum+tcp"
                    Host      = $Hashrefinery_Host
                    Port      = $Hashrefinery_Port
                    User1     = $global:Wallets.Wallet1.$($(arg).Passwordcurrency1).address
                    User2     = $global:Wallets.Wallet2.$($(arg).Passwordcurrency2).address
                    User3     = $global:Wallets.Wallet3.$($(arg).Passwordcurrency3).address
                    Pass1     = "c=$($global:Wallets.Wallet1.keys),id=$($(arg).RigName1)"
                    Pass2     = "c=$($global:Wallets.Wallet2.keys),id=$($(arg).RigName2)"
                    Pass3     = "c=$($global:Wallets.Wallet3.keys),id=$($(arg).RigName3)"
                    Meets_Threshold = $Meets_Threshold
                }
            }
        }
    }
}
    
