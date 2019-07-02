$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$zpool_Request = [PSCustomObject]@{ }
$zpool_Sorted = [PSCustomObject]@{ }
$zpool_UnSorted = [PSCustomObject]@{ }

$DoAutoCoin = $false
if ($(arg).Coin.Count -eq 0) { $DoAutoCoin = $true }
$(arg).Coin | % { if ($_ -eq "") { $DoAutoCoin = $true } }
if ($(arg).Ban_GLT -eq "Yes") { $NoGLT = "GLT" }

if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

if ($Name -in $(arg).PoolName) {
    try { $zpool_Request = Invoke-RestMethod "https://zpool.ca/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        log "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }

    Switch ($(arg).Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "sea" }
    }
   
    $zpool_Request.PSObject.Properties.Name | ForEach-Object { $zpool_Request.$_ | Add-Member "sym" $_ }
    $zpool_Request.PSObject.Properties.Name | ForEach-Object {
        $Algo = $zpool_Request.$_.Algo.ToLower()
        $zpool_Request.$_ | Add-Member "Original_Algo" $Algo
        $zpool_Request.$_.Algo = $global:Config.Pool_Algos.PSObject.Properties.Name | % { if ($Algo -in $global:Config.Pool_Algos.$_.alt_names) { $_ } }
    }
    $zpoolAlgos = @()
    $zpoolAlgos += $(vars).Algorithm
    $zpoolAlgos += $(arg).ASIC_ALGO

    $Algos = $zpoolAlgos | ForEach-Object { if ($Bad_pools.$_ -notcontains $Name) { $_ } }
    $zpool_Request.PSObject.Properties.Value | % { $_.Estimate = [Decimal]$_.Estimate }

    ##Add Active Coins for calcs
    $Active = $zpool_Request.PSObject.Properties.Value | Where-Object sym -in $(vars).ActiveSymbol
    if ($Active) { $Active | ForEach-Object { $zpool_Sorted | Add-Member $_.sym $_ -Force } }

    if ($(arg).Coin.Count -gt 1 -and $(arg).Coin -ne "") {
        $CoinsOnly = $zpool_Request.PSObject.Properties.Value | Where-Object sym -in $(arg).Coin
        if ($CoinsOnly) { $CoinsOnly | ForEach-Object { $zpool_Sorted | Add-Member $_.sym $_ -Force } }
    }

    if ($DoAutoCoin) {
        $Algos | ForEach-Object {

            $Selected = $_

            $Best = $zpool_Request.PSObject.Properties.Value | 
            Where-Object Algo -eq $Selected | 
            Where-Object Algo -in $(vars).FeeTable.zpool.keys | 
            Where-Object Algo -in $(vars).divisortable.zpool.Keys |
            Where-Object { $global:Config.Pool_Algos.$($_.Algo) } |
            Where-Object { $Name -notin $global:Config.Pool_Algos.$($_.sym).exclusions } |
            Where-Object Sym -notin $(vars).BanHammer |
            Where-Object Sym -notlike "*$NoGLT*" |
            Where-Object estimate -gt 0 | 
            Where-Object hashrate -ne 0 | 
            Sort-Object Price -Descending |
            Select -First 1

            if ($Best -ne $null) { $zpool_Sorted | Add-Member $Best.sym $Best -Force }
        }
    }

    if ($(arg).Stat_All -eq "Yes") {
        $Algos | ForEach-Object {

            $Selected = $_

            $NotBest = $zpool_Request.PSObject.Properties.Value |
            Where-Object Algo -eq $Selected |
            Where-Object Algo -in $(vars).FeeTable.zpool.keys |
            Where-Object Algo -in $(vars).divisortable.zpool.Keys |
            Where-Object { $global:Config.Pool_Algos.$($_.Algo) } |
            Where-Object { $Name -notin $global:Config.Pool_Algos.$($_.sym).exclusions } |
            Where-Object Sym -notin $(vars).BanHammer |
            Where-Object estimate -gt 0 |
            Where-Object hashrate -ne 0 |
            Sort-Object Price -Descending |
            Select-Object -skip 1

            if ($NotBest -ne $null) { $NotBest | ForEach-Object { $zpool_UnSorted | Add-Member $_.sym $_ -Force } }

        }

        $zpool_UnSorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
            if ($Name -notin $global:Config.Pool_Algos.$zpool_Symbol.exclusions -and $zpool_Symbol -notin $(vars).BanHammer) {
                $zpool_Algorithm = $zpool_UnSorted.$_.algo.ToLower()
                $zpool_Symbol = $zpool_UnSorted.$_.sym.ToUpper()
                $Fees = [Double]$(vars).FeeTable.zpool.$zpool_Algorithm
                $Estimate = [Double]$zpool_UnSorted.$_.estimate * 0.001
                $Divisor = (1000000 * [Double]$(vars).divisortable.zpool.$zpool_Algorithm)
                $Workers = [Double]$zpool_UnSorted.$_.Workers
                $Cut = ConvertFrom-Fees $Fees $Workers $Estimate $Divisor
                try { 
                    $StatAlgo = $zpool_Symbol -replace "`_", "`-" 
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_coin_profit" -Value $Cut
                }
                catch { log "Failed To Calculate Stat For $zpool_Symbol" }
            }
        }

        $zpool_Sorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

            $zpool_Algorithm = $zpool_Sorted.$_.algo.ToLower()
            $zpool_Symbol = $zpool_Sorted.$_.sym.ToUpper()
            $zap = "zap=$zpool_Symbol,"
            $zpool_Port = $zpool_Sorted.$_.port
            $Zpool_Host = "$($zpool_Request.$_.Original_Algo).$($region).mine.zpool.ca$X"
            $Fees = [Double]$(vars).FeeTable.zpool.$zpool_Algorithm
            $Estimate = [Double]$zpool_Sorted.$_.estimate * 0.001
            $Divisor = (1000000 * [Double]$(vars).divisortable.zpool.$zpool_Algorithm)
            $Workers = $zpool_Sorted.$_.Workers

            $Cut = ConvertFrom-Fees $Fees $Workers $Estimate $Divisor

            $Stat = Global:Set-Stat -Name "$($Name)_$($zpool_Symbol)_coin_profit" -Value $Cut

            $Pass1 = $global:Wallets.Wallet1.Keys
            $User1 = $global:Wallets.Wallet1.$($(arg).Passwordcurrency1).address
            $Pass2 = $global:Wallets.Wallet2.Keys
            $User2 = $global:Wallets.Wallet2.$($(arg).Passwordcurrency2).address
            $Pass3 = $global:Wallets.Wallet3.Keys
            $User3 = $global:Wallets.Wallet3.$($(arg).Passwordcurrency3).address

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
                
            if ($(vars).All_AltWallets) {
                $(vars).All_AltWallets.PSObject.Properties.Name | ForEach-Object {
                    $Sym = $_
                    $Zpool_Sym = $zpool_Symbol -split "-" | Select -First 1
                    if ($(vars).All_AltWallets.$Sym.exchange -ne "Yes") {
                        $Pass1 = $Sym
                        $Pass2 = $Sym
                        $Pass3 = $Sym
                        $mc = ""
                        if ($(vars).All_AltWallets.$Sym.address -ne "add address of coin if you wish to mine to that address, or leave alone." -and $(vars).All_AltWallets.$_.address -ne "") {
                            $User1 = $(vars).All_AltWallets.$Sym.address
                            $User2 = $(vars).All_AltWallets.$Sym.address
                            $User3 = $(vars).All_AltWallets.$Sym.address
                        }
                    }
                }
            }
    
            [PSCustomObject]@{
                Symbol    = "$zpool_Symbol-Coin"
                Algorithm = $zpool_Algorithm
                Price     = $Stat.$($(arg).Stat_Coin)
                Protocol  = "stratum+tcp"
                Host      = $zpool_Host
                Port      = $zpool_Port
                User1     = $User1
                User2     = $User2
                User3     = $User3
                Pass1     = "c=$Pass1,$($zap)id=$($(arg).RigName1)"
                Pass2     = "c=$Pass2,$($zap)id=$($(arg).RigName2)"
                Pass3     = "c=$Pass3,$($zap)id=$($(arg).RigName3)"
            } 
        }
    }
}