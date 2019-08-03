
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$ahashpool_Request = [PSCustomObject]@{ } 
$Meets_Threshold = $true;
$Shuffle = 0;

if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" }

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
    Where-Object { $ahashpool_Request.$_.estimate_current -gt 0 } | 
    Where-Object {
        $Algo = $ahashpool_Request.$_.name.ToLower();
        $local:ahashpool_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $ahashpool_Algorithm
    } |
    ForEach-Object {
        if ($(vars).Algorithm -contains $ahashpool_Algorithm -or $(arg).ASIC_ALGO -contains $ahashpool_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$ahashpool_Algorithm.exclusions -and $ahashpool_Algorithm -notin $(vars).BanHammer) {
                
                $StatAlgo = $ahashpool_Algorithm -replace "`_", "`-"
                $StatPath = ".\stats\($Name)_$($StatAlgo)_profit.txt"
                if(Test-Path $StatPath) { $Estimate = [Double]$ahashpool_Request.$_.estimate_current }
                else { $Estimate = [Double]$ahashpool_Request.$_.actual_last24h * 0.001}

                if ($(arg).mode -eq "easy") {
                    if( $ahashpool_Request.$_.actual_last24h -eq 0 ){ $Meets_Threshold = $false } else {$Meets_Threshold = $True}
                    $Shuffle = Shuffle $ahashpool_Request.$_.estimate_current $ahashpool_Request.$_.actual_last24h
                } else {$Meets_Threshold = $true}

                $ahashpool_Host = "$_.mine.ahashpool.com$X"
                $ahashpool_Port = $ahashpool_Request.$_.port
                $Divisor = 1000000 * $ahashpool_Request.$_.mbtc_mh_factor
                $Hashrate = $ahashpool_Request.$_.hashrate

                $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( $Estimate / $Divisor * (1 - ($ahashpool_Request.$_.fees / 100))) -Shuffle $Shuffle
                if (-not $(vars).Pool_Hashrates.$ahashpool_Algorithm) { $(vars).Pool_Hashrates.Add("$ahashpool_Algorithm", @{ }) }
                if (-not $(vars).Pool_Hashrates.$ahashpool_Algorithm.$Name) { $(vars).Pool_Hashrates.$ahashpool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" }) }

                $Level = $Stat.$($(arg).Stat_Algo)
                if($(arg).mode -eq "easy") {
                    $SmallestValue = 1E-20 
                    $Level = [Math]::Max($Level + ($Level * $Stat.Deviation), $SmallestValue)
                }

                [PSCustomObject]@{
                    Symbol          = "$ahashpool_Algorithm-Algo"
                    Algorithm       = $ahashpool_Algorithm
                    Price           = $Level
                    Protocol        = "stratum+tcp"
                    Host            = $ahashpool_Host
                    Port            = $ahashpool_Port
                    User1           = $global:Wallets.Wallet1.$($(arg).Passwordcurrency1).address
                    User2           = $global:Wallets.Wallet2.$($(arg).Passwordcurrency2).address
                    User3           = $global:Wallets.Wallet3.$($(arg).Passwordcurrency3).address
                    Pass1           = "c=$($global:Wallets.Wallet1.keys),id=$($(arg).RigName1)"
                    Pass2           = "c=$($global:Wallets.Wallet2.keys),id=$($(arg).RigName2)"
                    Pass3           = "c=$($global:Wallets.Wallet3.keys),id=$($(arg).RigName3)"
                    Meets_Threshold = $Meets_Threshold
                }
            }
        }
    }
}
