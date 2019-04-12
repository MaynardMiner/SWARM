
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$fairpool_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try { $fairpool_Request = Invoke-RestMethod "https://fairpool.pro/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Warning "SWARM contacted ($Name) but there was no response."; return }
 
    if (($fairpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }

    Switch ($Location) {
        "US" { $Region = "us1.fairpool.pro" }
        default { $Region = "eu1.fairpool.pro" }
    }
  
    $fairpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $fairpool_Request.$_.hashrate -gt 0 } | Where-Object { $Naming.$($fairpool_Request.$_.name) } | ForEach-Object {
 
        $fairpool_Algorithm = $fairpool_Request.$_.name.ToLower()

        if ($Algorithm -contains $fairpool_Algorithm -or $ASIC_ALGO -contains $fairpool_Algorithm) {
            if ($Bad_pools.$fairpool_Algorithm -notcontains $Name) {
                $fairpool_Host = "$region"
                $fairpool_Port = $fairpool_Request.$_.port
                $Divisor = (1000000 * $fairpool_Request.$_.mbtc_mh_factor)
                $Fees = $fairpool_Request.$_.fees
                $Workers = $fairpool_Request.$_.Workers
                $Estimate = if ($Stat_Algo -eq "Day") { [Double]$fairpool_Request.$_.estimate_last24h }else { [Double]$fairpool_Request.$_.estimate_current }

                $Stat = Set-Stat -Name "$($Name)_$($fairpool_Algorithm)_profit" -Value ([Double]$Estimate / $Divisor * (1 - ($fairpool_Request.$_.fees / 100)))
                if ($Stat_Algo -eq "Day") { $CStat = $Stat.Live }else { $CStat = $Stat.$Stat_Algo }
   
                [PSCustomObject]@{
                    Priority      = $Priorities.Pool_Priorities.$Name
                    Symbol        = $fairpool_Algorithm
                    Mining        = $fairpool_Algorithm
                    Algorithm     = $fairpool_Algorithm
                    Price         = $CStat
                    StablePrice   = $Stat.Week
                    MarginOfError = $Stat.Fluctuation
                    Protocol      = "stratum+tcp"
                    Host          = $fairpool_Host
                    Port          = $fairpool_Port
                    User1         = $global:Wallets.Wallet1.$PasswordCurrency1.address
                    User2         = $global:Wallets.Wallet2.$PasswordCurrency2.address
                    User3         = $global:Wallets.Wallet3.$PasswordCurrency3.address
                    CPUser        = $global:Wallets.Wallet1.$PasswordCurrency1.address                    
                    CPUPass       = "c=$($global:Wallets.Wallet1.keys),id=$Rigname1"
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
