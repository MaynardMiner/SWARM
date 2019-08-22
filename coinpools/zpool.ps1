$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Meets_Threshold = $true

$zpool_Request = [PSCustomObject]@{ }
$zpool_Sorted = [PSCustomObject]@{ }

if ($(arg).Ban_GLT -eq "Yes") { $NoGLT = "GLT" }
else { $NoGLT = "SWARM1234" }
if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

## Skip if user didn't specify
if ($Name -in $(arg).PoolName) {

    try { $zpool_Request = Invoke-RestMethod "http://zpool.ca/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        log "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }
   
    ## Add symbol to the list for sorting
    $zpool_Request.PSObject.Properties.Name | ForEach-Object { $zpool_Request.$_ | Add-Member "sym" $_ }

    ## Convert to universal naming schema
    $zpool_Request.PSObject.Properties.Name | ForEach-Object {
        $Algo = $zpool_Request.$_.Algo.ToLower()
        $zpool_Request.$_ | Add-Member "Original_Algo" $Algo
        $zpool_Request.$_.Algo = $global:Config.Pool_Algos.PSObject.Properties.Name | % { if ($Algo -in $global:Config.Pool_Algos.$_.alt_names) { $_ } }
    }

    # Make an algo list, include asic algorithms not usually in SWARM
    ## Remove algos that users/SWARM have banned.
    $Algos = @()
    $Algos += $(vars).Algorithm
    $Algos += $(arg).ASIC_ALGO
    $Algos = $Algos | ForEach-Object { if ($Bad_pools.$_ -notcontains $Name) { $_ } }

    ## Convert estimate to decimal
    $zpool_Request.PSObject.Properties.Value | ForEach-Object { $_.Estimate = [Decimal]$_.Estimate }

    ## Automatically add Active Coins for calcs. Active Coins are coins that are currently being mined.
    $Active = $zpool_Request.PSObject.Properties.Value | Where-Object sym -in $(vars).ActiveSymbol
    if ($Active) { $Active | ForEach-Object { $zpool_Sorted | Add-Member $_.sym $_ -Force } }

    ## Single Coin/Specic Coin mining
    if ($(arg).Coin.Count -gt 1 -and $(arg).Coin -ne "") {
        $CoinsOnly = $zpool_Request.PSObject.Properties.Value | Where-Object sym -in $(arg).Coin
        if ($CoinsOnly) { $CoinsOnly | ForEach-Object { $zpool_Sorted | Add-Member $_.sym $_ -Force } }
    }
    else {
        $Algos | ForEach-Object {
            $Selected = $_
            $zpool_Request.PSObject.Properties.Value | 
            Where-Object Algo -eq $Selected |
            Where-Object Algo -in $(vars).FeeTable.zpool.keys | 
            Where-Object Algo -in $(vars).divisortable.zpool.Keys |
            Where-Object { $global:Config.Pool_Algos.$($_.Algo) } |
            Where-Object { $Name -notin $global:Config.Pool_Algos.$($_.Algo).exclusions } |
            Where-Object Sym -notin $(vars).BanHammer |
            Where-Object Sym -notlike "*$NoGLT*" |
            Where-Object noautotrade -eq "0" | 
            Where-Object estimate -gt 0 |
            ForEach-Object { $zpool_Sorted | Add-Member $_.sym $_ -Force }
        }
    }

    $zpool_Sorted | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $zpool_Algo = $zpool_Sorted.$_.algo.ToLower()
        $zpool_Symbol = $zpool_Sorted.$_.sym.ToUpper()
        $StatAlgo = $zpool_Symbol -replace "`_", "`-" 
        $Divisor = 1000000 * [Double]$(vars).divisortable.zpool.$zpool_Algo
        $zpool_Fees = [Double]$(vars).FeeTable.zpool.$zpool_Algo
        $zpool_Estimate = [Double]$zpool_Sorted.$_.estimate * 0.001
        $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_coin_profit" -Value ([double]$zpool_Estimate / $Divisor * (1 - ($zpool_fees / 100))) -Shuffle $zpool_Sorted.$_.Shuffle     
        $Level = $Stat.$($(arg).Stat_Algo)
        $zpool_Sorted.$_ | Add-Member "Level" $Level 
    }

    Switch ($(arg).Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "sea" }
    }    

    ## Break the algos to groups to sort it down.
    $Algos | ForEach-Object {
        $Selected = $_

        $zpool_Sorted.PSObject.Properties.Value | 
        Where-Object Algo -eq $Selected | 
        Sort-Object Level -Descending | 
        Select-Object -First 1 | 
        ForEach-Object { 

            $zpool_Algo = $_.algo.ToLower()
            $zpool_Symbol = $_.sym.ToUpper()
            $mc = "zap=$zpool_Symbol,"
            $zpool_Port = $_.port
            $zpool_Host = "$($_.Original_Algo).$($region).mine.zpool.ca$X"

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
                    $zpool_sym = $zpool_Symbol -split "-" | Select -First 1
                    if ($Sym -eq $zpool_sym -or $Sym -eq $zpool_Symbol) {
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
            }

            [Pool]::New(
                ## Symbol
                "$ZPool_Symbol-Coin",
                ## Algorithm
                $Zpool_Algo,
                ## Level
                $Level,
                ## Stratum
                "stratum+tcp",
                ## Pool_Host
                $Zpool_Host,
                ## Pool_Port
                $Zpool_Port,
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