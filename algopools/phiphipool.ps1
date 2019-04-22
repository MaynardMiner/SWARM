$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$phiphipool_Request = [PSCustomObject]@{ } 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

if ($Poolname -eq $Name) {
    try { $phiphipool_Request = Invoke-RestMethod "https://www.phi-phi-pool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Warning "SWARM contacted ($Name) but there was no response."; return }
 
    if (($phiphipool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }
  
    switch ($Location) {
        "ASIA" { $region = "asia" }
        "US" { $region = "us" }
        "EUROPE" { $Region = "eu" }
    }
  
    $phiphipool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $phiphipool_Request.$_.hashrate -gt 0 } | Where-Object { $Naming.$($phiphipool_Request.$_.name) } | ForEach-Object {

        $phiphipool_Algorithm = $phiphipool_Request.$_.name.ToLower()

        if ($Algorithm -contains $phiphipool_Algorithm -or $ASIC_ALGO -contains $phiphipool_Algorithm) {
            if ($Bad_pools.$phiphipool_Algorithm -notcontains $Name) {
                $phiphipool_Port = $phiphipool_Request.$_.port
                $phiphipool_Host = "$($Region).phi-phi-pool.com"
                $Divisor = (1000000 * $phiphipool_Request.$_.mbtc_mh_factor)
                $Fees = $phiphipool_Request.$_.fees
                $Workers = $phiphipool_Request.$_.Workers
                $StatPath = ".\stats\($Name)_$($phiphipool_Algorithm)_profit.txt"
                $Hashrate = $phiphipool_Request.$_.hashrate

                if (-not (Test-Path $StatPath)) {
                    $Stat = Set-Stat -Name "$($Name)_$($phiphipool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$phiphipool_Request.$_.estimate_last24h / $Divisor * (1 - ($phiphipool_Request.$_.fees / 100)))
                } 
                else {
                    $Stat = Set-Stat -Name "$($Name)_$($phiphipool_Algorithm)_profit" -HashRate $HashRate -Value ( [Double]$phiphipool_Request.$_.estimate_current / $Divisor * (1 - ($phiphipool_Request.$_.fees / 100)))
                }

                if(-not $global:Pool_Hashrates.$phiphipool_Algorithm){$global:Pool_Hashrates.Add("$phiphipool_Algorithm",@{})}
                $global:Pool_Hashrates.$phiphipool_Algorithm.Add("$Name",@{HashRate = "$($Stat.HashRate)"; Percent = ""})

                [PSCustomObject]@{
                    Priority      = $Priorities.Pool_Priorities.$Name
                    Symbol        = "$phiphipool_Algorithm-Algo"
                    Mining        = $phiphipool_Algorithm
                    Algorithm     = $phiphipool_Algorithm
                    Price         = $Stat.$Stat_Algo
                    Protocol      = "stratum+tcp"
                    Host          = $phiphipool_Host
                    Port          = $phiphipool_Port
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
