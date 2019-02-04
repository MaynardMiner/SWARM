
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$ahashpool_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try {$ahashpool_Request = Invoke-RestMethod "https://www.ahashpool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} 
    catch {Write-Warning "SWARM contacted ($Name) but there was no response."; return}
 
    if (($ahashpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    } 
  
    $ahashpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$ahashpool_Request.$_.hashrate -gt 0} |  Where-Object {$Naming.$($ahashpool_Request.$_.name)} | ForEach-Object {
 
        $ahashpool_Algorithm = $ahashpool_Request.$_.name

        if ($Algorithm -contains $ahashpool_Algorithm -and $Bad_pools.$ahashpool_Algorithm -notcontains $Name) {
            $ahashpool_Host = "$_.mine.ahashpool.com"
            $ahashpool_Port = $ahashpool_Request.$_.port
            $Fees = $ahashpool_Request.$_.fees
            $Divisor = (1000000 * $ahashpool_Request.$_.mbtc_mh_factor)
            $Workers = $ahashpool_Request.$_.Workers
            $Estimate = if ($Stat_Algo -eq "Day") {[Double]$ahashpool_Request.$_.estimate_last24h}else {[Double]$ahashpool_Request.$_.estimate_current}
            #$Cut = ConvertFrom-Fees $Fees $Workers $Estimate

            $SmallestValue = 1E-20
            $Stat = Set-Stat -Name "$($Name)_$($ahashpool_Algorithm)_profit" -Value ([Double]$Estimate/$Divisor *(1-($ahashpool_Request.$_.fees/100)))
            if ($Stat_Algo -eq "Day") {$Stats = $Stat.Live}else {$Stats = $Stat.$Stat_Algo}

            [PSCustomObject]@{
                Priority      = $Priorities.Pool_Priorities.$Name
                Symbol        = $ahashpool_Algorithm
                Mining        = $ahashpool_Algorithm
                Algorithm     = $ahashpool_Algorithm
                Price         = $Stats
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $ahashpool_Host
                Port          = $ahashpool_Port
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
