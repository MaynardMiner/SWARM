$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Meets_Threshold = $true

$zergpool_Request = [PSCustomObject]@{ }
$Zergpool_Sorted = [PSCustomObject]@{ }
$Zergpool_UnSorted = [PSCustomObject]@{ }

if ($(arg).Ban_GLT -eq "Yes") { $NoGLT = "GLT" }
if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

## Skip if user didn't specify
if ($Name -in $(arg).PoolName) {

    try { $zergpool_Request = Invoke-RestMethod "http://zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        log "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }
   
    ## Add symbol to the list for sorting
    $zergpool_Request.PSObject.Properties.Name | ForEach-Object { $zergpool_Request.$_ | Add-Member "sym" $_ }

    ## Convert to universal naming schema
    $zergpool_Request.PSObject.Properties.Name | ForEach-Object {
        $Algo = $zergpool_Request.$_.Algo.ToLower()
        $zergpool_Request.$_ | Add-Member "Original_Algo" $Algo
        $zergpool_Request.$_.Algo = $global:Config.Pool_Algos.PSObject.Properties.Name | % { if ($Algo -in $global:Config.Pool_Algos.$_.alt_names) { $_ } }
    }

    # Make an algo list, include asic algorithms not usually in SWARM
    ## Remove algos that users/SWARM have banned.
    $ZergAlgos = @()
    $ZergAlgos += $(vars).Algorithm
    $ZergAlgos += $(arg).ASIC_ALGO
    $Algos = $ZergAlgos | ForEach-Object { if ($Bad_pools.$_ -notcontains $Name) { $_ } }

    ## Convert estimate to decimal
    $zergpool_Request.PSObject.Properties.Value | ForEach-Object { $_.Estimate = [Decimal]$_.Estimate }

    ## Automatically add Active Coins for calcs. Active Coins are coins that are currently being mined.
    $Active = $zergpool_Request.PSObject.Properties.Value | Where-Object sym -in $(vars).ActiveSymbol
    if ($Active) { $Active | ForEach-Object { $Zergpool_Sorted | Add-Member $_.sym $_ -Force } }

    ## Single Coin/Specic Coin mining
    if ($(arg).Coin.Count -gt 1 -and $(arg).Coin -ne "") {
        $CoinsOnly = $zergpool_Request.PSObject.Properties.Value | Where-Object sym -in $(arg).Coin
        if ($CoinsOnly) { $CoinsOnly | ForEach-Object { $Zergpool_Sorted | Add-Member $_.sym $_ -Force } }
    }
    else {
        $Algos | ForEach-Object {
            $Selected = $_
            $AlgoPool_list = $zergpool_Request.PSObject.Properties.Value | 
                Where-Object Algo -eq $Selected |
                Where-Object Algo -in $(vars).FeeTable.zergpool.keys | 
                Where-Object Algo -in $(vars).divisortable.zergpool.Keys |
                Where-Object { $global:Config.Pool_Algos.$($_.Algo) } |
                Where-Object { $Name -notin $global:Config.Pool_Algos.$($_.Algo).exclusions } |
                Where-Object Sym -notin $(vars).BanHammer |
                Where-Object Sym -notlike "*$NoGLT*" |
                Where-Object noautotrade -eq "0" | 
                Where-Object estimate -gt 0 | 
                Where-Object hashrate -ne 0 

            if ($(arg).mode -eq "easy") {
                $AlgoPool_list | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
                    $_ | Add-Member "Shuffle" (Coin_Shuffle $Zergpool_Request.$_.estimate $Zergpool_Request.$_.actual_last24h)
                }
            }          

            ## Only choose coins with 24 hour returns or choose all coins (since they all have historical ttf longer than 24 hr).
            if ( ($Algopool."24h_btc_shared" | Measure-Object -Sum | select -ExpandProperty Sum) -ne 0 ) {
                $BestCoins = $AlgoPool_list | Where "24h_btc_shared" -ne 0
            }
            else { $BestCoins = $AlgoPool_list }

            ## Narrow the coins with pipeline (faster):
            ## Not directly banned
            ## Not a GLT coin (if -Ban_GLT is "Yes")
            ## Is specified by user (i.e. the algorithm wasn't specifically banned.)
            ## estimate isn't 0
            $Best = $BestCoins | Sort-Object Price -Descending | Select -First 1

            ## Add It to the sorting list
            if ($Best) { $Zergpool_Sorted | Add-Member $Best.sym $Best -Force }

            ## Add remaining coins for historical stats if user specified a
            ## time frame higher than live. If it is live, there is no point
            ## to record all coins.
            if ($(arg).Stat_Coin -ne "live") {
                $AlgoPool_list | Where sym -ne $Best.sym | ForEach-Object {
                    $Zergpool_UnSorted | Add-Member $_.sym $_ -Force
                }
            }
        }
    }

    ## First stat the historical coins.
    $Zergpool_UnSorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
        $Zergpool_Algorithm = $Zergpool_UnSorted.$_.algo.ToLower()
        $Zergpool_Symbol = $Zergpool_UnSorted.$_.sym.ToUpper()

        $StatAlgo = $Zergpool_Algorithm -replace "`_", "`-"
        $StatPath = ".\stats\($Name)_$($StatAlgo)_profit.txt"
        if (Test-Path $StatPath) { $Estimate = [Double]$Zergpool_Request.$_.estimate * 0.001 }
        else { $Estimate = [Double]$Zergpool_Request.$_."24h_btc_shared" }

        if ($(arg).mode -eq "easy") { $Shuffle = Shuffle $Zergpool_Request.$_.estimate_current $Zergpool_Request.$_.actual_last24h }

        $zergpool_Fees = [Double]$(vars).FeeTable.zergpool.$Zergpool_Algorithm
        $Divisor = 1000000 * [Double]$(vars).divisortable.zergpool.$Zergpool_Algorithm 

        $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_coin_profit" -Value ( $Estimate / $Divisor * (1 - ($zergpool_fees / 100))) 
    }

    ## Now to the best coins.
    $Zergpool_Sorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

        if ($(arg).Mode -eq "easy") {
            if ( $Zergpool_Sorted.$_.estimate -lt $Zergpool_Sorted.$_."24h_btc_shared" -or [Double]$Zergpool_Sorted.$_."24h_btc_shared" -eq 0) {
                $Meets_Threshold = Global:Get-Requirement $Zergpool_Sorted.$_.estimate $Zergpool_Sorted.$_."24h_btc_shared"
            }
            else { $Meets_Threshold = $true }
        }

        $Zergpool_Algorithm = $Zergpool_Sorted.$_.algo.ToLower()
        $Zergpool_Symbol = $Zergpool_Sorted.$_.sym.ToUpper()
        $mc = "mc=$Zergpool_Symbol,"
        $zergpool_Port = $Zergpool_Sorted.$_.port
        $zergpool_Host = "$($Zergpool_Sorted.$_.Original_Algo).mine.zergpool.com$X"
        $zergpool_Fees = [Double]$(vars).FeeTable.zergpool.$Zergpool_Algorithm
        $zergpool_Estimate = [Double]$Zergpool_Sorted.$_.estimate * 0.001
        $Divisor = 1000000 * [Double]$(vars).divisortable.zergpool.$Zergpool_Algorithm 
        $StatAlgo = $Zergpool_Symbol -replace "`_", "`-" 
        $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_coin_profit" -Value ([double]$zergpool_Estimate / $Divisor * (1 - ($zergpool_fees / 100))) 

        ## Wallet Swapping/Solo mining
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
            $(vars).All_AltWallets.keys | ForEach-Object {
                $Sym = $_
                $Zerg_Sym = $Zergpool_Symbol -split "-" | Select -First 1
                if ($Sym -eq $Zerg_Sym -or $Sym -eq $Zergpool_Symbol) {
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
                    if ($(vars).All_AltWallets.$Sym.solo -eq "Yes") {
                        $mc += "m=solo,"
                    }    
                }   
            }
        }

        [PSCustomObject]@{
            Symbol          = "$Zergpool_Symbol-Coin"
            Algorithm       = $zergpool_Algorithm
            Price           = $Stat.$($(arg).Stat_Coin)
            Protocol        = "stratum+tcp"
            Host            = $zergpool_Host
            Port            = $zergpool_Port
            User1           = $User1
            User2           = $User2
            User3           = $User3
            Pass1           = "c=$Pass1,$($mc)id=$($(arg).RigName1)"
            Pass2           = "c=$Pass2,$($mc)id=$($(arg).RigName2)"
            Pass3           = "c=$Pass3,$($mc)id=$($(arg).RigName3)"
            Meets_Threshold = $Meets_Threshold
        } 
    }
}