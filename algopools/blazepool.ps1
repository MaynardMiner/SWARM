
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$blazepool_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try { $blazepool_Request = Invoke-RestMethod "http://api.blazepool.com/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Warning "SWARM contacted ($Name) but there was no response."; return }
 
    if (($blazepool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }   
  
    $blazepool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $blazepool_Request.$_.hashrate -gt 0 } | Where-Object { $Naming.$($blazepool_Request.$_.name) } | ForEach-Object {

        $blazepool_Algorithm = $blazepool_Request.$_.name.ToLower()

        if ($Algorithm -contains $blazepool_Algorithm -or $ASIC_ALGO -contains $blazepool_Algorithm) {
            if ($Bad_pools.$blazepool_Algorithm -notcontains $Name) {
                $blazepool_Host = "$_.mine.blazepool.com"
                $blazepool_Port = $blazepool_Request.$_.port
                $Divisor = (1000000 * $blazepool_Request.$_.mbtc_mh_factor)
                $Fees = $blazepool_Request.$_.fees
                $Workers = $blazepool_Request.$_.Workers
                $StatPath = ".\stats\($Name)_$($blazepool_Algorithm)_profit.txt"
                $Hashrate = $blazepool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$blazepool_Request.$_.estimate_last24h / $Divisor * (1 - ($blazepool_Request.$_.fees / 100)))
                } 
                else {
                    $Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$blazepool_Request.$_.estimate_current / $Divisor * (1 - ($blazepool_Request.$_.fees / 100)))
                }

                if(-not $global:Pool_Hashrates.$blazepool_Algorithm){$global:Pool_Hashrates.Add("$blazepool_Algorithm",@{})}
                $global:Pool_Hashrates.$blazepool_Algorithm.Add("$Name","$($Stat.HashRate)")
    
                [PSCustomObject]@{
                    Priority      = $Priorities.Pool_Priorities.$Name
                    Symbol        = "$blazepool_Algorithm-Algo"
                    Mining        = $blazepool_Algorithm
                    Algorithm     = $blazepool_Algorithm
                    Price         = $Stat.$Stat_Algo
                    Protocol      = "stratum+tcp"
                    Host          = $blazepool_Host
                    Port          = $blazepool_Port
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