$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$zpool_Request = [PSCustomObject]@{ }
$zpool_Sorted = [PSCustomObject]@{ }
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

if ($Poolname -eq $Name) {
    try { $zpool_Request = Invoke-RestMethod "http://zpool.ca/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        Write-Warning "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }

    Switch ($Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "sea" }
    }
   
    $zpool_Request.PSObject.Properties.Name | ForEach-Object { $zpool_Request.$_ | Add-Member "sym" $_ }

    $Algorithm | ForEach-Object {
        $Selected = if ($Bad_pools.$_ -notcontains $Name) { $_ }
        $Best = $zpool_Request.PSObject.Properties.Value | Where-Object Algo -eq $Selected | Where-Object Algo -in $global:FeeTable.zpool.keys | Where-Object Algo -in $global:divisortable.zpool.Keys | Where-Object estimate -ne "0.00000" | Where-Object hashrate -ne 0 | Sort-Object Price -Descending | Select-Object -First 1
        if ($Best -ne $null) { $zpool_Sorted | Add-Member $Best.sym $Best }
    }
    $ASIC_ALGO | ForEach-Object {
        $Selected = if ($Bad_pools.$_ -notcontains $Name) { $_ }
        $Best = $zpool_Request.PSObject.Properties.Value | Where-Object Algo -eq $Selected | Where-Object Algo -in $global:FeeTable.zpool.keys | Where-Object Algo -in $global:divisortable.zpool.Keys | Where-Object estimate -ne "0.00000" | Where-Object hashrate -ne 0 | Sort-Object Price -Descending | Select-Object -First 1
        if ($Best -ne $null) { $zpool_Sorted | Add-Member $Best.sym $Best -Force }
    }

    $zpool_Sorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

        $zpool_Algorithm = $zpool_Request.$_.algo.ToLower()
        $zpool_Symbol = $zpool_Sorted.$_.sym.ToUpper()
        $zpool_Coin = $zpool_Sorted.$_.Name.Tolower()
        $zpool_Port = $zpool_Sorted.$_.port
        $Zpool_Host = "$($ZPool_Algorithm).$($region).mine.zpool.ca"

        $zpool_Fees = [Double]$global:FeeTable.zpool.$zpool_Algorithm

        $zpool_Estimate = [Double]$zpool_Sorted.$_.estimate * 0.001

        $Divisor = (1000000 * [Double]$global:DivisorTable.zpool.$zpool_Algorithm)

        $Stat = Set-Stat -Name "$($Name)_$($zpool_Symbol)_coin_profit" -Value ([double]$zpool_Estimate / $Divisor * (1 - ($zpool_fees / 100)))

        $Pass1 = $global:Wallets.Wallet1.Keys
        $User1 = $global:Wallets.Wallet1.$Passwordcurrency1.address
        $Pass2 = $global:Wallets.Wallet2.Keys
        $User2 = $global:Wallets.Wallet2.$Passwordcurrency2.address
        $Pass3 = $global:Wallets.Wallet3.Keys
        $User3 = $global:Wallets.Wallet3.$Passwordcurrency3.address

        if ($global:Wallets.AltWallet1.keys) {
            $global:Wallets.AltWallet1.Keys | ForEach-Object {
                if ($global:Wallets.AltWallet1.$_.Pools -contains $Name) {
                    $Pass1 = $_;
                    $User1 = $global:Wallets.AltWallet1.$_.address;
                }
            }
        }
        if ($global:Wallets.AltWallet2.keys) {
            $global:Wallets.AltWallet2.Keys | ForEach-Object {
                if ($global:Wallets.AltWallet2.$_.Pools -contains $Name) {
                    $Pass2 = $_;
                    $User2 = $global:Wallets.AltWallet2.$_.address;
                }
            }
        }
        if ($global:Wallets.AltWallet3.keys) {
            $global:Wallets.AltWallet3.Keys | ForEach-Object {
                if ($global:Wallets.AltWallet3.$_.Pools -contains $Name) {
                    $Pass3 = $_;
                    $User3 = $global:Wallets.AltWallet3.$_.address;
                }
            }
        }
                
        if ($global:All_AltWallets) {
            $global:All_AltWallets | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                if ($_ -eq $zpool_Symbol) {
                    $Pass1 = $zpool_Symbol
                    $User1 = $global:All_AltWallets.$_
                    $Pass2 = $zpool_Symbol
                    $User2 = $global:All_AltWallets.$_
                    $Pass3 = $zpool_Symbol
                    $User3 = $global:All_AltWallets.$_
                }
            }
        }

        [PSCustomObject]@{
            Priority      = $Priorities.Pool_Priorities.$Name
            Symbol        = "$zpool_Symbol-Coin"
            Mining        = $zpool_Algorithm
            Algorithm     = $zpool_Algorithm
            Price         = $Stat.$Stat_Coin
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $zpool_Host
            Port          = $zpool_Port
            User1         = $User1
            User2         = $User2
            User3         = $User3
            CPUser        = $User1
            CPUPass       = "c=$Pass1,zap=$zpool_Symbol,id=$Rigname1"
            Pass1         = "c=$Pass1,zap=$zpool_Symbol,id=$Rigname1"
            Pass2         = "c=$Pass2,zap=$zpool_Symbol,id=$Rigname2"
            Pass3         = "c=$Pass3,zap=$zpool_Symbol,id=$Rigname3"
            Location      = $Location
            SSL           = $false
        } 
    }
}
