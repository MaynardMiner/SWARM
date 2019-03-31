$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$zergpool_Request = [PSCustomObject]@{}
$Zergpool_Sorted = [PSCustomObject]@{}
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

if ($Poolname -eq $Name) {
    try {$zergpool_Request = Invoke-RestMethod "http://zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop}
    catch {
        Write-Warning "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }
   
    $zergpool_Request.PSObject.Properties.Name | foreach { $zergpool_Request.$_ | Add-Member "sym" $_ }

    $Algorithm | foreach {
        $Selected = if ($Bad_pools.$_ -notcontains $Name) {$_}
        $Best = $zergpool_Request.PSObject.Properties.Value | Where Algo -eq $Selected | Where noautotrade -eq "0" | Where estimate -ne "0.00000" | Sort-Object Price -Descending | Select -First 1
        if ($Best -ne $null) {$Zergpool_Sorted | Add-Member $Best.sym $Best}
    }

    $Zergpool_Sorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | foreach {

        $Zergpool_Algorithm = $Zergpool_Request.$_.algo.ToLower()
        $Zergpool_Symbol = $Zergpool_Sorted.$_.sym.ToUpper()
        $zergpool_Coin = $Zergpool_Sorted.$_.Name.Tolower()
        $zergpool_Port = $Zergpool_Sorted.$_.port
        $zergpool_Host = "$($Zergpool_Sorted.$_.algo).mine.zergpool.com"
        $zergpool_Fees = .5
        $zergpool_Estimate = [Double]$Zergpool_Sorted.$_.estimate * .001
        $Divisor = (1000000 * $Zergpool_Sorted.$_.mbtc_mh_factor)

        $Stat = Set-Stat -Name "$($Name)_$($Zergpool_Symbol)_coin_profit" -Value ([Double]$zergpool_Estimate / $Divisor * (1 - ($zergpool_fees / 100)))

        $Pass1 = $global:Wallets.Wallet1.Keys
        $User1 = $global:Wallets.Wallet1.BTC.address
        $Pass2 = $global:Wallets.Wallet2.Keys
        $User2 = $global:Wallets.Wallet2.BTC.address
        $Pass3 = $global:Wallets.Wallet3.Keys
        $User3 = $global:Wallets.Wallet3.BTC.address

        $global:Wallets.AltWallet1.Keys | ForEach-Object {
            if ($global:Wallets.AltWallet1.$_.Pools -contains $Name) {
                $Pass1 = $_;
                $User1 = $global:Wallets.AltWallet1.$_.address;
            }
        }
        $global:Wallets.AltWallet2.Keys | ForEach-Object {
            if ($global:Wallets.AltWallet2.$_.Pools -contains $Name) {
                $Pass2 = $_;
                $User2 = $global:Wallets.AltWallet2.$_.address;
            }
        }
        $global:Wallets.AltWallet3.Keys | ForEach-Object {
            if ($global:Wallets.AltWallet3.$_.Pools -contains $Name) {
                $Pass3 = $_;
                $User3 = $global:Wallets.AltWallet3.$_.address;
            }
        }

        [PSCustomObject]@{
            Priority      = $Priorities.Pool_Priorities.$Name
            Symbol        = $Zergpool_Symbol
            Mining        = $Zergpool_Algorithm
            Algorithm     = $zergpool_Algorithm
            Price         = $Stat.$Stat_Coin
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $zergpool_Host
            Port          = $zergpool_Port
            User1         = $global:Wallets.Wallet1.BTC.address
            User2         = $global:Wallets.Wallet2.BTC.address
            User3         = $global:Wallets.Wallet3.BTC.address
            CPUser        = $global:Wallets.Wallet1.BTC.address
            CPUPass       = "c=$($global:Wallets.Wallet1.keys),mc=$Zergpool_Symbol"
            Pass1         = "c=$($global:Wallets.Wallet1.keys),mc=$Zergpool_Symbol"
            Pass2         = "c=$($global:Wallets.Wallet2.keys),mc=$Zergpool_Symbol"
            Pass3         = "c=$($global:Wallets.Wallet3.keys),mc=$Zergpool_Symbol"
            Location      = $Location
            SSL           = $false
        } 
    }
}
