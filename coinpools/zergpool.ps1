$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$zergpool_Request = [PSCustomObject]@{ }
$Zergpool_Sorted = [PSCustomObject]@{ }
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

if ($Poolname -eq $Name) {
    try { $zergpool_Request = Invoke-RestMethod "http://zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        Write-Warning "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Warning "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }
   
    $zergpool_Request.PSObject.Properties.Name | ForEach-Object { $zergpool_Request.$_ | Add-Member "sym" $_ }

    $Algorithm | ForEach-Object {
        $Selected = if ($Bad_pools.$_ -notcontains $Name) { $_ }
        $Best = $zergpool_Request.PSObject.Properties.Value | Where-Object Algo -eq $Selected | Where-Object Algo -in $global:FeeTable.zergpool.keys | Where-Object Algo -in $global:divisortable.zergpool.Keys | Where-Object noautotrade -eq "0" | Where-Object estimate -ne "0.00000" | Where-Object hashrate -ne 0 | Sort-Object Price -Descending | Select-Object -First 1
        if ($Best -ne $null) { $Zergpool_Sorted | Add-Member $Best.sym $Best }
    }
    $ASIC_ALGO | ForEach-Object {
        $Selected = if ($Bad_pools.$_ -notcontains $Name) { $_ }
        $Best = $zergpool_Request.PSObject.Properties.Value | Where-Object Algo -eq $Selected | Where-Object Algo -in $global:FeeTable.zergpool.keys | Where-Object Algo -in $global:divisortable.zergpool.Keys | Where-Object noautotrade -eq "0" | Where-Object estimate -ne "0.00000" | Where-Object hashrate -ne 0 | Sort-Object Price -Descending | Select-Object -First 1
        if ($Best -ne $null) { $Zergpool_Sorted | Add-Member $Best.sym $Best -Force }
    }

    $Zergpool_Sorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

        $Zergpool_Algorithm = $Zergpool_Request.$_.algo.ToLower()
        $Zergpool_Symbol = $Zergpool_Sorted.$_.sym.ToUpper()
        $zergpool_Coin = $Zergpool_Sorted.$_.Name.Tolower()
        $zergpool_Port = $Zergpool_Sorted.$_.port
        $zergpool_Host = "$($Zergpool_Sorted.$_.algo).mine.zergpool.com"

        $zergpool_Fees = [Double]$global:FeeTable.zergpool.$Zergpool_Algorithm

        $zergpool_Estimate = [Double]$Zergpool_Sorted.$_.estimate * 0.001

        $Divisor = (1000000 * [Double]$global:DivisorTable.zergpool.$Zergpool_Algorithm)
        
        try{ $Stat = Set-Stat -Name "$($Name)_$($Zergpool_Symbol)_coin_profit" -Value ([double]$zergpool_Estimate / $Divisor * (1 - ($zergpool_fees / 100))) }catch{ Write-Warning "Failed To Calculate Stat For $Zergpool_Symbol" }

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
                if ($_ -eq $Zergpool_Symbol) {
                    $Pass1 = $Zergpool_Symbol
                    $User1 = $global:All_AltWallets.$_
                    $Pass2 = $Zergpool_Symbol
                    $User2 = $global:All_AltWallets.$_
                    $Pass3 = $Zergpool_Symbol
                    $User3 = $global:All_AltWallets.$_
                }
            }
        }

        [PSCustomObject]@{
            Estimate      = $zergpool_Estimate
            Divisor       = $Divisor
            Fees          = $zergpool_Fees
            Priority      = $Priorities.Pool_Priorities.$Name
            Symbol        = "$Zergpool_Symbol-Coin"
            Mining        = $Zergpool_Algorithm
            Algorithm     = $zergpool_Algorithm
            Price         = $Stat.$Stat_Coin
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $zergpool_Host
            Port          = $zergpool_Port
            User1         = $User1
            User2         = $User2
            User3         = $User3
            CPUser        = $User1
            CPUPass       = "c=$Pass1,mc=$Zergpool_Symbol,id=$Rigname1"
            Pass1         = "c=$Pass1,mc=$Zergpool_Symbol,id=$Rigname1"
            Pass2         = "c=$Pass2,mc=$Zergpool_Symbol,id=$Rigname2"
            Pass3         = "c=$Pass3,mc=$Zergpool_Symbol,id=$Rigname3"
            Location      = $Location
            SSL           = $false
        } 
    }
}
