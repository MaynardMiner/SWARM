
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$fairpool_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try {$fairpool_Request = Invoke-RestMethod "https://fairpool.pro/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} 
    catch {Write-Warning "SWARM contacted ($Name) but there was no response."; return}
 
    if (($fairpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }

    Switch ($Location) {
        "US" {$Region = "us1.fairpool.pro"}
        default {$Region = "eu1.fairpool.pro"}
    }
  
    $fairpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$fairpool_Request.$_.hashrate -gt 0} | Where-Object {$Naming.$($fairpool_Request.$_.name)} | ForEach-Object {
 
        $fairpool_Algorithm = Get-Algorithm $fairpool_Request.$_.name

        if ($Algorithm -eq $fairpool_Algorithm) {
            $fairpool_Host = "$region.fairpool.pro"
            $fairpool_Port = $fairpool_Request.$_.port
            $Divisor = (1000000 * $fairpool_Request.$_.mbtc_mh_factor)
            $Fees = $fairpool_Request.$_.fees
            $Workers = $fairpool_Request.$_.Workers
            $Estimate = if ($Stat_Algo -eq "Day") {[Double]$fairpool_Request.$_.estimate_last24h}else {[Double]$fairpool_Request.$_.estimate_current}
            #$Cut = ConvertFrom-Fees $Fees $Workers $Estimate

            $SmallestValue = 1E-20
            $Stat = Set-Stat -Name "$($Name)_$($fairpool_Algorithm)_profit" -Value ([Double]$Estimate/$Divisor *(1-($fairpool_Request.$_.fees/100)))
            if ($Stat_Algo -eq "Day") {$Stats = $Stat.Live}else {$Stats = $Stat.$Stat_Algo}
   
            [PSCustomObject]@{
                Priority      = $Priorities.Pool_Priorities.$Name
                Symbol        = $fairpool_Algorithm
                Mining        = $fairpool_Algorithm
                Algorithm     = $fairpool_Algorithm
                Price         = $Stats
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $fairpool_Host
                Port          = $fairpool_Port
                User1         = $Wallet1
                User2         = $Wallet2
                User3         = $Wallet3
                CPUser        = $Wallet1
                CPUPass       = "c=$Passwordcurrency1,ID=$Rigname1"
                Pass1         = "c=$Passwordcurrency1,ID=$Rigname1"
                Pass2         = "c=$Passwordcurrency2,ID=$Rigname2"
                Pass3         = "c=$Passwordcurrency3,ID=$Rigname3"
                Location      = $Location
                SSL           = $false
            }
        }
    }
}
