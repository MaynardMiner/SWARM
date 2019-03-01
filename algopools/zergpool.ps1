$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Zergpool_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
 
if ($Poolname -eq $Name) {
    try {$Zergpool_Request = Invoke-RestMethod "http://api.zergpool.com:8080/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} 
    catch {Write-Warning "SWARM contacted ($Name) but there was no response."; return}
  
    if (($Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    } 
     
    $Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$Zergpool_Request.$_.hashrate -gt 0} |  Where-Object {$Naming.$($Zergpool_Request.$_.name)} | ForEach-Object {
    
        $Zergpool_Algorithm = $Zergpool_Request.$_.name.ToLower()
  
        if ($Algorithm -contains $Zergpool_Algorithm -and $Bad_pools.$Zergpool_Algorithm -notcontains $Name) {
            $Zergpool_Port = $Zergpool_Request.$_.port
            $Zergpool_Host = "$($Zergpool_Algorithm).mine.zergpool.com"
            $Divisor = (1000000 * $Zergpool_Request.$_.mbtc_mh_factor)
            $Fees = $Zergpool_Request.$_.fees
            $Workers = $Zergpool_Request.$_.Workers
            $Estimate = if ($Stat_Algo -eq "Day") {[Double]$Zergpool_Request.$_.estimate_last24h}else {[Double]$Zergpool_Request.$_.estimate_current}
            #$Cut = ConvertFrom-Fees $Fees $Workers $Estimate

            $SmallestValue = 1E-20
            $Stat = Set-Stat -Name "$($Name)_$($Zergpool_Algorithm)_profit" -Value ([Double]$Estimate/$Divisor *(1-($Zergpool_Request.$_.fees/100)))
            if ($Stat_Algo -eq "Day") {$CStat = $Stat.Live}else {$CStat = $Stat.$Stat_Algo}
         
            If ($AltWallet1 -ne '') {$zWallet1 = $AltWallet1}
            else {$zwallet1 = $Wallet1}
            if ($AltWallet2 -ne '') {$zWallet2 = $AltWallet2}
            else {$zwallet2 = $Wallet2}
            if ($AltWallet3 -ne '') {$zWallet3 = $AltWallet3}
            else {$zwallet3 = $Wallet3}
            if ($AltPassword1 -ne '') {$zpass1 = $Altpassword1}
            else {$zpass1 = $Passwordcurrency1}
            if ($AltPassword2 -ne '') {$zpass2 = $AltPassword2}
            else {$zpass2 = $Passwordcurrency2}
            if ($AltPassword3 -ne '') {$zpass3 = $AltPassword3}
            else {$zpass3 = $Passwordcurrency3}
            [PSCustomObject]@{
                Priority      = $Priorities.Pool_Priorities.$Name
                Symbol        = $Zergpool_Algorithm
                Mining        = $Zergpool_Algorithm
                Algorithm     = $Zergpool_Algorithm
                Price         = $CStat
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $Zergpool_Host
                Port          = $Zergpool_Port
                User1         = $zWallet1
                User2         = $zWallet2
                User3         = $zWallet3
                CPUser        = $zWallet1
                CPUPass       = "c=$zpass1,ID=$Rigname1$SWARMPass"
                Pass1         = "c=$zpass1,ID=$Rigname1$SWARMPass"
                Pass2         = "c=$zpass2,ID=$Rigname2$SWARMPass"
                Pass3         = "c=$zpass3,ID=$Rigname3$SWARMPass"
                Location      = $Location
                SSL           = $false
            }
        }
    }
}
