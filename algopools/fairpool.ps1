
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$fairpool_Request = [PSCustomObject]@{ } 
$Meets_Threshold = $true

if($(arg).xnsub -eq "Yes"){$X = "#xnsub"}
 
if ($Name -in $(arg).PoolName) {
    try { $fairpool_Request = Invoke-RestMethod "https://fairpool.pro/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($fairpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }

    Switch ($(arg).Location) {
        "US" { $Region = "us1.fairpool.pro" }
        default { $Region = "eu1.fairpool.pro" }
    }
  
    $fairpool_Request | 
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { [Double]$fairpool_Request.$_.estimate_current -gt 0 } | 
    Where-Object {
        $Algo = $fairpool_Request.$_.name.ToLower();
        $local:fairpool_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $fairpool_Algorithm
    } |
    ForEach-Object {
        if ($(vars).Algorithm -contains $fairpool_Algorithm -or $(arg).ASIC_ALGO -contains $fairpool_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$fairpool_Algorithm.exclusions -and $fairpool_Algorithm -notin $(vars).BanHammer) {

                $StatAlgo = $fairpool_Algorithm -replace "`_", "`-"
                $StatPath = ".\stats\($Name)_$($StatAlgo)_profit.txt"
                if(Test-Path $StatPath) { $Estimate = [Double]$fairpool_Request.$_.estimate_current }
                else { $Estimate = [Double]$fairpool_Request.$_.estimate_last24h }

                if ($(arg).mode -eq "easy") {
                    if( $fairpool_Request.$_.actual_last24h -eq 0 ){ $Meets_Threshold = $false } else {$Meets_Threshold = $True}
                    $Shuffle = Shuffle $fairpool_Request.$_.estimate_current $fairpool_Request.$_.actual_last24h
                } else {$Meets_Threshold = $true}


                $fairpool_Host = "$region$X"
                $fairpool_Port = $fairpool_Request.$_.port
                $Divisor = 1000000 * $fairpool_Request.$_.mbtc_mh_factor
                $Hashrate = $blockpool_Request.$_.hashrate

                $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ( $Estimate / $Divisor * (1 - ($fairpool_Request.$_.fees / 100))) -Shuffle $Shuffle
                if (-not $(vars).Pool_Hashrates.$fairpool_Algorithm) { $(vars).Pool_Hashrates.Add("$fairpool_Algorithm", @{ }) }
                if (-not $(vars).Pool_Hashrates.$fairpool_Algorithm.$Name) { $(vars).Pool_Hashrates.$fairpool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" }) }

                $Level = $Stat.$($(arg).Stat_Algo)
                if($(arg).mode -eq "easy") {
                    $SmallestValue = 1E-20 
                    $Level = [Math]::Max($Level + ($Level * $Stat.Deviation), $SmallestValue)
                }
   
                [PSCustomObject]@{
                    Symbol    = "$fairpool_Algorithm-Algo"
                    Algorithm = $fairpool_Algorithm
                    Price     = $Level
                    Protocol  = "stratum+tcp"
                    Host      = $fairpool_Host
                    Port      = $fairpool_Port
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
