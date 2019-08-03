
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$blazepool_Request = [PSCustomObject]@{ } 
$Meets_Threshold = $true


if($(arg).xnsub -eq "Yes"){$X = "#xnsub"}
 
if ($Name -in $(arg).PoolName) {
    try { $blazepool_Request = Invoke-RestMethod "http://api.blazepool.com/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($blazepool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }   
  
    $blazepool_Request | 
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { $blazepool_Request.$_.estimate_current -gt 0 } | 
    Where-Object {
        $Algo = $blazepool_Request.$_.name.ToLower();
        $local:blazepool_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $blazepool_Algorithm
    } |
    ForEach-Object {
        if ($(vars).Algorithm -contains $blazepool_Algorithm -or $(arg).ASIC_ALGO -contains $blazepool_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$blazepool_Algorithm.exclusions -and $blazepool_Algorithm -notin $(vars).BanHammer) {

                $StatAlgo = $blazepool_Algorithm -replace "`_", "`-"
                $StatPath = ".\stats\($Name)_$($StatAlgo)_profit.txt"
                if(Test-Path $StatPath) { $Estimate = [Double]$blazepool_Request.$_.estimate_current }
                else { $Estimate = [Double]$blazepool_Request.$_.actual_last24h * 0.001}

                if ($(arg).mode -eq "easy") {
                    if( $blazepool_Request.$_.actual_last24h -eq 0 ){ $Meets_Threshold = $false } else {$Meets_Threshold = $True}
                    $Shuffle = Shuffle $blazepool_Request.$_.estimate_current $blazepool_Request.$_.actual_last24h
                } else {$Meets_Threshold = $true}

                $blazepool_Host = "$_.mine.blazepool.com$X"
                $blazepool_Port = $blazepool_Request.$_.port
                $Divisor = 1000000 * $blazepool_Request.$_.mbtc_mh_factor
                $Hashrate = $blazepool_Request.$_.hashrate

                $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( $Estimate / $Divisor * (1 - ($blazepool_Request.$_.fees / 100))) -Shuffle $Shuffle
                if (-not $(vars).Pool_Hashrates.$blazepool_Algorithm) { $(vars).Pool_Hashrates.Add("$blazepool_Algorithm", @{ }) }
                if (-not $(vars).Pool_Hashrates.$blazepool_Algorithm.$Name) { $(vars).Pool_Hashrates.$blazepool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" }) }
    
                $Level = $Stat.$($(arg).Stat_Algo)
                if($(arg).mode -eq "easy") {
                    $SmallestValue = 1E-20 
                    $Level = [Math]::Max($Level + ($Level * $Stat.Deviation), $SmallestValue)
                }

                [PSCustomObject]@{
                    Symbol    = "$blazepool_Algorithm-Algo"
                    Algorithm = $blazepool_Algorithm
                    Price     = $Level
                    Protocol  = "stratum+tcp"
                    Host      = $blazepool_Host
                    Port      = $blazepool_Port
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