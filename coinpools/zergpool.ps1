$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Meets_Threshold = $true

$zergpool_Request = [PSCustomObject]@{ }
$Zergpool_Sorted = [PSCustomObject]@{ }
$SmallestValue = 1E-20 

if ($(arg).Ban_GLT -eq "Yes") { $NoGLT = "GLT" }
else { $NOGLT = "SWARM1234" } 
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
            $zergpool_Request.PSObject.Properties.Value | 
            Where-Object Algo -eq $Selected |
            Where-Object Algo -in $(vars).FeeTable.zergpool.keys | 
            Where-Object Algo -in $(vars).divisortable.zergpool.Keys |
            Where-Object { $global:Config.Pool_Algos.$($_.Algo) } |
            Where-Object { $Name -notin $global:Config.Pool_Algos.$($_.Algo).exclusions } |
            Where-Object Sym -notin $(vars).BanHammer |
            Where-Object Sym -notlike "*$NoGLT*" |
            Where-Object noautotrade -eq "0" | 
            Where-Object estimate -gt 0 |
            ForEach-Object { $Zergpool_Sorted | Add-Member $_.sym $_ -Force }
        }
    }

    $Zergpool_Sorted | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $Zergpool_Algo = $Zergpool_Sorted.$_.algo.ToLower()
        $Zergpool_Symbol = $Zergpool_Sorted.$_.sym.ToUpper()
        $StatAlgo = $Zergpool_Symbol -replace "`_", "`-" 
        $Divisor = 1000000 * [Double]$(vars).divisortable.zergpool.$Zergpool_Algo
        $zergpool_Fees = [Double]$(vars).FeeTable.zergpool.$Zergpool_Algo
        $zergpool_Estimate = [Double]$Zergpool_Sorted.$_.estimate * 0.001
        $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_coin_profit" -Value ([double]$zergpool_Estimate / $Divisor * (1 - ($zergpool_fees / 100))) -Shuffle $Zergpool_Sorted.$_.Shuffle     
        $Level = $Stat.$($(arg).Stat_Algo)
        $Zergpool_Sorted.$_ | Add-Member "Level" $Level 
    }

    ## Break the algos to groups to sort it down.
    $Algos | ForEach-Object {
        $Selected = $_

        $Zergpool_Sorted.PSObject.Properties.Value | 
        Where-Object Algo -eq $Selected | 
        Sort-Object Level -Descending | 
        Select-Object -First 1 | 
        ForEach-Object { 

            $Zergpool_Algo = $_.algo.ToLower()
            $Zergpool_Symbol = $_.sym.ToUpper()
            $mc = "mc=$Zergpool_Symbol,"
            $zergpool_Port = $_.port
            $zergpool_Host = "$($_.Original_Algo).mine.zergpool.com$X"
            $previous = $null

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
                        if ($(vars).All_AltWallets.$Sym.params -ne "enter additional params here, such as 'm=solo' or m=party.partypassword") {
                            $mc += "m=$($(vars).All_AltWallets.$Sym.params),"
                        }    
                    }   
                }
            }

            [Pool]::New(
                ## Symbol
                "$ZergPool_Symbol-Coin",
                ## Algorithm
                $Zergpool_Algo,
                ## Level
                $Level,
                ## Stratum
                "stratum+tcp",
                ## Pool_Host
                $zergpool_Host,
                ## Pool_Port
                $zergpool_Port,
                ## User1
                $User1,
                ## User2
                $User2,
                ## User3
                $User3,
                ## Pass1
                "c=$Pass1,$($mc)id=$($(arg).RigName1)",
                ## Pass2
                "c=$Pass2,$($mc)id=$($(arg).RigName2)",
                ## Pass3
                "c=$Pass3,$($mc)id=$($(arg).RigName3)",
                ## Previous
                $previous
            )
        }
    }
}