$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$nlpool_Request = [PSCustomObject]@{}
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

if ($Poolname -eq $Name) {
    try {$nlpool_Request = Invoke-RestMethod "https://nlpool.nl/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop}
    catch {Write-Warning "SWARM contacted ($Name) but there was no response."; return}
   
    if (($nlpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }

    $nlpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$nlpool_Request.$_.hashrate -gt 0} | Where-Object {$Naming.$($nlpool_Request.$_.name)} | Where-Object {$nlpool_Request.$_.name -NE "sha256"} | Where-Object {$($nlpool_Request.$_.estimate_current) -ne "0.00000000"} | ForEach-Object {
        
        $nlpoolAlgo_Algorithm = $nlpool_Request.$_.name.ToLower()

        if ($Algorithm -contains $nlpoolAlgo_Algorithm -and $Bad_pools.$nlpoolAlgo_Algorithm -notcontains $Name) {
            $nlpoolAlgo_Host = "mine.nlpool.nl"
            $nlpoolAlgo_Port = $nlpool_Request.$_.port
            $Divisor = (1000000 * $nlpool_Request.$_.mbtc_mh_factor)
            $Fees = $nlpool_Request.$_.fees
            $Workers = $nlpool_Request.$_.Workers
            $Estimate = if ($Stat_Algo -eq "Day") {[Double]$nlpool_Request.$_.estimate_last24h}else {[Double]$nlpool_Request.$_.estimate_current}
            #$Cut = ConvertFrom-Fees $Fees $Workers $Estimate

            $SmallestValue = 1E-20
            $Stat = Set-Stat -Name "$($Name)_$($nlpoolAlgo_Algorithm)_profit" -Value ([Double]$Estimate/$Divisor *(1-($nlpool_Request.$_.fees/100)))
            if ($Stat_Algo -eq "Day") {$CStat = $Stat.Live}else {$CStat = $Stat.$Stat_Algo}
        
            If ($AltWallet1 -ne '') {$nWallet1 = $AltWallet1}
            else {$nWallet1 = $Wallet1}
            if ($AltWallet2 -ne '') {$nWallet2 = $AltWallet2}
            else {$nWallet2 = $Wallet2}
            if ($AltWallet3 -ne '') {$nWallet3 = $AltWallet3}
            else {$nWallet3 = $Wallet3}
            if ($AltPassword1 -ne '') {$npass1 = $AltPassword1}
            else {$npass1 = $PasswordCurrency1}
            if ($AltPassword2 -ne '') {$npass2 = $AltPassword2}
            else {$npass2 = $PasswordCurrency2}
            if ($AltPassword3 -ne '') {$npass3 = $AltPassword3}
            else {$npass3 = $PasswordCurrency3}
            [PSCustomObject]@{
                Priority      = $Priorities.Pool_Priorities.$Name
                Symbol        = $nlpoolAlgo_Algorithm
                Mining        = $nlpoolAlgo_Algorithm
                Algorithm     = $nlpoolAlgo_Algorithm
                Price         = $CStat
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $nlpoolAlgo_Host
                Port          = $nlpoolAlgo_Port
                User1         = $nWallet1
                User2         = $nWallet2
                User3         = $nWallet3
                CPUser        = $nWallet1
                CPUPass       = "c=$npass1,ID=$Rigname1"
                Pass1         = "c=$npass1,ID=$Rigname1"
                Pass2         = "c=$npass2,ID=$Rigname2"
                Pass3         = "c=$npass3,ID=$Rigname3"
                Location      = $Location
                SSL           = $false
            }
        }
    }
}
