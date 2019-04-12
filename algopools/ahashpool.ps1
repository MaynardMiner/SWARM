
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$ahashpool_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try { $ahashpool_Request = Invoke-RestMethod "https://www.ahashpool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Warning "SWARM contacted ($Name) but there was no response."; return }
 
    if (($ahashpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    } 
  
    $ahashpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $ahashpool_Request.$_.hashrate -gt 0 } | Where-Object { $Naming.$($ahashpool_Request.$_.name) } | ForEach-Object {
 
        $ahashpool_Algorithm = $ahashpool_Request.$_.name.ToLower()

        if ($Algorithm -contains $ahashpool_Algorithm -or $ASIC_ALGO -contains $ahashpool_Algorithm) {
            if ($Bad_pools.$ahashpool_Algorithm -notcontains $Name) {
                $ahashpool_Host = "$_.mine.ahashpool.com"
                $ahashpool_Port = $ahashpool_Request.$_.port
                $Fees = $ahashpool_Request.$_.fees
                $Divisor = (1000000 * $ahashpool_Request.$_.mbtc_mh_factor)
                $Workers = $ahashpool_Request.$_.Workers
                $Estimate = if ($Stat_Algo -eq "Day") { [Double]$ahashpool_Request.$_.estimate_last24h }else { [Double]$ahashpool_Request.$_.estimate_current }

                $Stat = Set-Stat -Name "$($Name)_$($ahashpool_Algorithm)_profit" -Value ([Double]$Estimate / $Divisor * (1 - ($ahashpool_Request.$_.fees / 100)))
                if ($Stat_Algo -eq "Day") { $CStat = $Stat.Live }else { $CStat = $Stat.$Stat_Algo }

                [PSCustomObject]@{
                    Priority      = $Priorities.Pool_Priorities.$Name
                    Symbol        = $ahashpool_Algorithm
                    Mining        = $ahashpool_Algorithm
                    Algorithm     = $ahashpool_Algorithm
                    Price         = $CStat
                    StablePrice   = $Stat.Week
                    MarginOfError = $Stat.Fluctuation
                    Protocol      = "stratum+tcp"
                    Host          = $ahashpool_Host
                    Port          = $ahashpool_Port
                    User1         = $global:Wallets.Wallet1.$PasswordCurrency1.address
                    User2         = $global:Wallets.Wallet2.$PasswordCurrency2.address
                    User3         = $global:Wallets.Wallet3.$PasswordCurrency3.address
                    CPUser        = $global:Wallets.Wallet1.$PasswordCurrency1.address                    
                    Pass1         = "c=$($global:Wallets.Wallet1.keys),id=$Rigname1"
                    Pass2         = "c=$($global:Wallets.Wallet2.keys),id=$Rigname2"
                    Pass3         = "c=$($global:Wallets.Wallet3.keys),id=$Rigname3"
                    Location      = $Location
                    SSL           = $false
                }
            }
        }
    }
}
