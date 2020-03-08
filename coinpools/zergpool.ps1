$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Pool_Request = [PSCustomObject]@{ }
$NOGLT = "DOESNOTMATTER"
$X = ""
if ($(arg).Ban_GLT -eq "Yes") { $NoGLT = "GLT" }
if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

## Skip if user didn't specify
if ($Name -in $(arg).PoolName) {
    try { $Pool_Request = Invoke-RestMethod "http://zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        log "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }
    if (($Pool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }

    # Make an algo list, include asic algorithms not usually in SWARM
    ## Remove algos that users/SWARM have banned.
    $Algos = @()
    $Algos += $(vars).Algorithm
    $Algos += $(arg).ASIC_ALGO
   
    ## Only get algos we need & convert name to universal schema
    $Pool_Algos = $global:Config.Pool_Algos;
    $Ban_Hammer = $global:Config.vars.BanHammer;
    $Fee_Table = $(vars).FeeTable.zergpool;
    $Divisor_Table = $(vars).divisortable.zergpool;
    $Active_Symbols = $(vars).ActiveSymbol;

    ## Change to universal naming schema and only items we need to add
    $Pool_Sorted = $Pool_Request.PSobject.Properties.Name | 
    Where-Object {
        if ($(arg).Coin.Count -ge 1 -and $(arg).Coin -ne "") {
            $_ -in $(arg).Coin 
        }
        else { $_ }
    } |
    ForEach-Object -Parallel {
        $request = $using:Pool_Request
        $Pipe_Algos = $using:Pool_Algos;
        $Pipe_Hammer = $using:Ban_Hammer;
        $Algo_List = $using:Algos;       
        $F_Table = $using:Fee_Table;
        $D_Table = $using:Divisor_Table;
        $Get_GLT = $using:NoGLT;
        ################################
        $request.$_ | Add-Member "sym" $_
        $request.$_ | Add-Member "Original_Algo" $request.$_.Algo.ToLower()
        $Algo = $request.$_.Algo
        $request.$_.Algo = $Pipe_Algos.PSObject.Properties.Name | Where-Object { $Algo -in $Pipe_Algos.$_.alt_names };
        if ( 
            $request.$_.algo -in $Algo_List -and
            $request.$_.sym -notin $Pipe_Algos.($_.Algo).exclusions -and
            $request.$_.sym -notin $Pipe_Hammer -and
            $request.$_.algo -in $F_Table.keys -and
            $request.$_.algo -in $D_Table.keys -and
            $request.$_.sym -notlike "*$Get_GLT*"
        ) {
            return $request.$_
        }
    } -ThrottleLimit $(arg).Throttle

    $Pool_Request = $null;
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    

    $Get_Params = $Global:Config.params
    $Pool_Sorted | ForEach-Object -Parallel {
        . .\build\powershell\global\classes.ps1
        $F_Table = $using:Fee_Table;
        $D_Table = $using:Divisor_Table;
        $P_Name = $using:Name
        $Params = $using:Get_Params
        $coin_name = $_.sym
        ## switch coin name if same
        if ($_.sym -eq $_.algo) { $coin_name = "$($_.sym)-COIN" }
        $StatName = "$($P_Name)_$($coin_name)"
        $Hashrate = [math]::Max($_.hashrate_shared, 1)
        $Divisor = 1000000 * [Convert]::ToDouble($D_Table.$($_.algo))
        $Fee = [Convert]::ToDouble($F_Table.$($_.algo))
        $Estimate = [Convert]::ToDecimal($_.estimate) * 0.001
        $actual = [Convert]::ToDecimal($_.'24h_btc_shared')
        $current = [Convert]::ToDecimal($Estimate / $Divisor * (1 - ($Fee / 100)))

        $Stat = [Pool_Stat]::New($StatName, $current, [Convert]::ToDecimal($Hashrate), $actual, $true)

        $Level = $Stat.$($Params.Stat_Coin)

        if ($Params.Historical_Bias) {
            $SmallestValue = 1E-20 
            $Values = $Params.Historical_Bias.Split("`:")
            $Max_Penalty = $Values | Select -First 1
            $Max_Bonus = $Values | Select -Last 1

            ## Penalize
            if ($Stat.Historical_Bias -lt 0) {
                $Deviation = [Math]::Max($Stat.Historical_Bias, ($Max_Penalty * -0.01))
            }
            ## Bonus
            else {
                $Deviation = [Math]::Min($Stat.Historical_Bias, ($Max_Bonus * 0.01))
            }
            $Level = [Math]::Max($Level + ($Level * $Deviation), $SmallestValue)
        }        

        $_ | Add-Member "Level" $Level 
        $_ | Add-Member "Previous" $stat.Actual
    }

    $Get_Wallets = $Global:Wallets
    $Get_AltWallets = $(vars).All_AltWallets
    ## Break the algos to groups to sort it down.
    $Pool_Data = $Algos | ForEach-Object -Parallel {
        . .\build\powershell\global\classes.ps1
        $Selected = $_
        $Sorted = $using:Pool_Sorted 
        $sub = $using:X
        $Wallets = $using:Get_Wallets
        $AltWallets = $using:Get_AltWallets
        $Params = $using:Get_Params
        $Active = $using:Active_Symbols;
        #######################################

        $To_Add = @()
        $To_Add += $Sorted | 
        Where-Object Algo -eq $Selected | 
        Where-Object { [Convert]::ToInt32($_."24h_blocks_shared") -ge $Params.Min_Blocks } |
        Sort-Object Level -Descending |
        Select-Object -First 1
        $To_Add += $Sorted | Where-Object { $_.Sym -in $Active -and $_ -notin $To_Add }

        $To_Add | ForEach-Object { 
            $Pool_Port = $_.port
            $Pool_Host = "$($_.Original_Algo.ToLower()).mine.zergpool.com$sub"
            $Pool_Algo = $_.algo.ToLower()
            $Pool_Symbol = $_.sym.ToUpper()
            $mc = "mc=$Pool_Symbol,"

            ## Wallet Swapping/Solo mining
            $Pass1 = $Wallets.Wallet1.Keys
            $User1 = $Wallets.Wallet1.$($Params.Passwordcurrency1).address
            $Pass2 = $Wallets.Wallet2.Keys
            $User2 = $Wallets.Wallet2.$($Params.Passwordcurrency2).address
            $Pass3 = $Wallets.Wallet3.Keys
            $User3 = $Wallets.Wallet3.$($Params.Passwordcurrency3).address

            if ($Wallets.AltWallet1.keys) {
                $Wallets.AltWallet1.Keys | ForEach-Object {
                    if ($Wallets.AltWallet1.$_.Pools -contains $Name) {
                        $Pass1 = $_;
                        $User1 = $Wallets.AltWallet1.$_.address;
                    }
                }
            }
            if ($Wallets.AltWallet2.keys) {
                $Wallets.AltWallet2.Keys | ForEach-Object {
                    if ($Wallets.AltWallet2.$_.Pools -contains $Name) {
                        $Pass2 = $_;
                        $User2 = $Wallets.AltWallet2.$_.address;
                    }
                }
            }
            if ($Wallets.AltWallet3.keys) {
                $Wallets.AltWallet3.Keys | ForEach-Object {
                    if ($Wallets.AltWallet3.$_.Pools -contains $Name) {
                        $Pass3 = $_;
                        $User3 = $Wallets.AltWallet3.$_.address;
                    }
                }
            }
                
            if ($AltWallets) {
                $AltWallets.keys | ForEach-Object {
                    $Sym = $_
                    $Pool_Sym = $Pool_Symbol -split "-" | Select -First 1
                    if ($Sym -eq $Pool_Sym -or $Sym -eq $Pool_Symbol) {
                        if ($AltWallets.$Sym.exchange -ne "Yes") {
                            $Pass1 = $Sym
                            $Pass2 = $Sym
                            $Pass3 = $Sym
                            $mc = ""
                            if ($AltWallets.$Sym.address -ne "add address of coin if you wish to mine to that address, or leave alone." -and $AltWallets.$_.address -ne "") {
                                $User1 = $AltWallets.$Sym.address
                                $User2 = $AltWallets.$Sym.address
                                $User3 = $AltWallets.$Sym.address
                            }
                        }
                        if ($AltWallets.$Sym.params -ne "enter additional params here, such as 'm=solo' or m=party.partypassword") {
                            $mc += "m=$($AltWallets.$Sym.params),"
                            $mc = $mc.replace("SOLO", "solo")
                            $mc = $mc.replace("PARTY", "party")
                        }    
                    }   
                }
            }

            [Pool]::New(
                ## Symbol
                "$Pool_Symbol-Coin",
                ## Algorithm
                $Pool_Algo,
                ## Level
                $_.Level,
                ## Stratum
                "stratum+tcp",
                ## Pool_Host
                $Pool_Host,
                ## Pool_Port
                $Pool_Port,
                ## User1
                $User1,
                ## User2
                $User2,
                ## User3
                $User3,
                ## Pass1
                "c=$Pass1,$($mc)id=$($Params.RigName1)",
                ## Pass2
                "c=$Pass2,$($mc)id=$($Params.RigName2)",
                ## Pass3
                "c=$Pass3,$($mc)id=$($Params.RigName3)",
                ## Previous
                $previous
            )
        }
    } -ThrottleLimit $(arg).Throttle
    
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    
    $Pool_Data
}