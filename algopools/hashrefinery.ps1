$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Hashrefinery_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
if ($Poolname -eq $Name) {
    try { $Hashrefinery_Request = Invoke-RestMethod "http://pool.hashrefinery.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Log "SWARM contacted ($Name) but there was no response."; return }

    if (($Hashrefinery_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }  
   
    $Hashrefinery_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $Hashrefinery_Request.$_.hashrate -gt 0 } | Where-Object { $Naming.$($Hashrefinery_Request.$_.name) } | ForEach-Object {
   
        $Hashrefinery_Algorithm = $Hashrefinery_Request.$_.name.ToLower()

        if ($Algorithm -contains $Hashrefinery_Algorithm -or $ASIC_ALGO -contains $Hashrefinery_Algorithm) {
            if ($Bad_pools.$Hashrefinery_Algorithm -notcontains $Name) {
                $Hashrefinery_Host = "$_.us.hashrefinery.com"
                $Hashrefinery_Port = $Hashrefinery_Request.$_.port
                $Divisor = (1000000 * $Hashrefinery_Request.$_.mbtc_mh_factor)
                $Fees = $Hashrefinery_Request.$_.fees
                $Workers = $Hashrefinery_Request.$_.Workers
                $StatPath = ".\stats\($Name)_$($Hashrefinery_Algorithm)_profit.txt"
                $Hashrate = $Hashrefinery_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $Stat = Set-Stat -Name "$($Name)_$($Hashrefinery_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$Hashrefinery_Request.$_.estimate_last24h / $Divisor * (1 - ($Hashrefinery_Request.$_.fees / 100)))
                } 
                else {
                    $Stat = Set-Stat -Name "$($Name)_$($Hashrefinery_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$Hashrefinery_Request.$_.estimate_current / $Divisor * (1 - ($Hashrefinery_Request.$_.fees / 100)))
                }

                if(-not $global:Pool_Hashrates.$Hashrefinery_Algorithm){$global:Pool_Hashrates.Add("$Hashrefinery_Algorithm",@{})}
                $global:Pool_Hashrates.$Hashrefinery_Algorithm.Add("$Name",@{HashRate = "$($Stat.HashRate)"; Percent = ""})
        
                [PSCustomObject]@{            
                    Priority      = $Priorities.Pool_Priorities.$Name
                    Symbol        = "$Hashrefinery_Algorithm-Algo"
                    Mining        = $Hashrefinery_Algorithm
                    Algorithm     = $Hashrefinery_Algorithm
                    Price         = $Stat.$Stat_Algo
                    Protocol      = "stratum+tcp"
                    Host          = $Hashrefinery_Host
                    Port          = $Hashrefinery_Port
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
    
