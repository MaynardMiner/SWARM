<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

. .\build\powershell\global\modules.ps1

if ($Name -in $(arg).PoolName) {
    $Pool_Request = [PSCustomObject]@{ }
    $NOGLT = "DOESNOTMATTER"
    $X = ""
    if ($(arg).Ban_GLT -eq "Yes") { $NoGLT = "GLT" }
    if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

    ## Skip if user didn't specify
    try { $Pool_Request = Invoke-RestMethod "https://zergpool.com/api/currencies" -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop }
    catch {
        return "WARNING: SWARM contacted ($Name) for a failed API check. (Coins)"; 
    }
    if (($Pool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        return "WARNING: SWARM contacted ($Name) but ($Name) the response was empty." 
    }

    # Make an algo list, include asic algorithms not usually in SWARM
    ## Remove algos that users/SWARM have banned.
    $Algos = @()
    $Algos += $(vars).Algorithm
    $Algos += $(arg).ASIC_ALGO
   
    ## Only get algos we need & convert name to universal schema
    $Pool_Algos = $global:Config.Pool_Algos;
    $Pool_Coins = $global:Config.Pool_Coins;
    $Ban_Hammer = $global:Config.vars.BanHammer;
    $Fee_Table = $(vars).FeeTable.zergpool;
    $Divisor_Table = $(vars).divisortable.zergpool;
    $Active_Symbols = $(vars).ActiveSymbol;
    $ttf = $(arg).ttf_maximum;

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
            $Pipe_Coins = $using:Pool_Coins;
            $Pipe_Hammer = $using:Ban_Hammer;
            $Algo_List = $using:Algos;       
            $F_Table = $using:Fee_Table;
            $D_Table = $using:Divisor_Table;
            $Get_GLT = $using:NoGLT;
            ################################
            if ($request.$_.Algo -ne $null) {
            $request.$_ | Add-Member "sym" $_
            $request.$_ | Add-Member "Original_Algo" $request.$_.Algo.ToLower()
            $Algo = $request.$_.Algo
            $request.$_.Algo = $Pipe_Algos.PSObject.Properties.Name | Where-Object { $Algo -in $Pipe_Algos.$_.alt_names };
            if ( 
                $request.$_.algo -in $Algo_List -and
                $request.$_.algo -notin $Pipe_Algos.($request.$_.Algo).exclusions -and
                $request.$_.sym -notin $Pipe_Algos.($request.$_.Algo).exclusions -and
                $request.$_.sym -notin $Pipe_Coins.($request.$_.sym).exclusions -and
                $request.$_.sym -notin $Pipe_Hammer -and
                $request.$_.algo -in $F_Table.keys -and
                $request.$_.algo -in $D_Table.keys -and
                $request.$_.sym -notlike "*$Get_GLT*"
            ) {
                return $request.$_
            }
        }
    } -ThrottleLimit $(arg).Throttle

    $Pool_Request = $null;
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    

    Switch ($(arg).Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "asia" }
        "JAPAN" { $region = "asia" }
    }    

    $Get_Params = $Global:Config.params
    $Pool_Sorted | ForEach-Object -Parallel {
        . .\build\powershell\global\classes.ps1
        $F_Table = $using:Fee_Table;
        $D_Table = $using:Divisor_Table;
        $P_Name = $using:Name
        $Params = $using:Get_Params
        $reg = $using:Region
        $coin_name = $_.sym;
        ## switch coin name if same
        if ($_.sym -eq $_.algo) { $coin_name = "$($_.sym)-COIN" }
        $StatName = "$($P_Name)_$($coin_name)"
        $Hashrate = [math]::Max([Convert]::ToDecimal($_.hashrate_shared), 1)
        $Divisor = 1000000 * [Convert]::ToDouble($_.mbtc_mh_factor)
        $Fee = [Convert]::ToDouble($F_Table.$($_.algo))
        $Estimate = [Convert]::ToDecimal($_.estimate) * 0.001
        $24h_actual = [Convert]::ToDecimal($_.actual_last24h_shared) * 0.001
        $current = [Convert]::ToDecimal($Estimate / $Divisor * (1 - ($Fee / 100)))
        $actual = [Convert]::ToDecimal($24h_actual / $Divisor * (1 - ($Fee / 100)))

        $Stat = [Pool_Stat]::New($StatName, $current, [Convert]::ToDecimal($Hashrate), $actual, $true)

        $Level = $Stat.$($Params.Stat_Coin)

        if ($Params.Historical_Bias -ne "") {
            $SmallestValue = 1E-20 
            $Values = $Params.Historical_Bias.Split("`:")
            $Max_Penalty = [double]($Values | Select -First 1)
            $Max_Bonus = [double]($Values | Select -Last 1)

            ## Penalize
            if ($Stat.Historical_Bias -lt 0) {
                $Deviation = [Math]::Max($Stat.Historical_Bias, ($Max_Penalty * -0.01))
                ### Make SWARM remove any coin that did not have any 24 hour returns
                ### Deviation -1 = -100%
                if ($Stat.Historical_Bias -eq -1) {
                    ## (estimate * -1) + estimate = 0
                    $Deviation = -1
                }
            }
            ## Bonus
            else {
                $Deviation = [Math]::Min($Stat.Historical_Bias, ($Max_Bonus * 0.01))
            }
            $Level = [Math]::Max($Level + ($Level * $Deviation), $SmallestValue)
        }        

        $_ | Add-Member "Level" $Level 
        $_ | Add-Member "Previous" $stat.Actual
    } -ThrottleLimit $(arg).Throttle

    $Get_Wallets = $Global:Wallets
    $Get_AltWallets = $(vars).All_AltWallets
    $Previous_Miners = $(vars).Previous_Miners
    ## Break the algos to groups to sort it down.
    $Pool_Data = $Algos | ForEach-Object -Parallel {
        . .\build\powershell\global\classes.ps1
        $Selected = $_
        $Sorted = $using:Pool_Sorted 
        $sub = $using:X
        $P_Name = $using:Name
        $A_Wallets = $using:Get_Wallets
        $AltWallets = $using:Get_AltWallets
        $Params = $using:Get_Params
        $reg = $using:region
        $Miners = $using:Previous_Miners;
        $max_ttf = $using:ttf;
        #######################################

        ## Get the current most profitable coin that meets
        ## arguments min_blocks and autotrade
        $To_Add = @()
        $To_Add += $Sorted | 
        Where-Object Algo -eq $Selected | 
        Where-Object { [Convert]::ToInt32($_."24h_blocks_shared") -ge $Params.Min_Blocks } |
        Where-Object { $_.noautotrade -eq 0 } |
        Where-Object {
            if ($max_ttf -ne 0) {
                if ($_.real_ttf -le $max_ttf) { $_ }
            }
            else { $_ }
        } |
        Sort-Object Level -Descending |
        Select-Object -First 1

        ## Add back in stats for running miners.
        ## Only add if it meets arguments min_blocks and autotrade
        $Miners | Foreach-Object {
            if ($_.Algo -eq $Selected -and $_.Symbol -notin $To_Add.Sym) {
                $Add_Stat = $Sorted | Where-Object sym -eq $_.Symbol | 
                Where-Object { [Convert]::ToInt32($_."24h_blocks_shared") -ge $Params.Min_Blocks } | 
                Where-Object { $_.noautotrade -eq 0 } 
                if ($Add_Stat) {
                    $To_Add += $Add_Stat
                }
            }
        }

        $To_Add | ForEach-Object { 
            $Pool_Port = $_.port
            $Pool_Host = "$($_.Original_Algo.ToLower()).$reg.mine.zergpool.com$sub"
            $Pool_Algo = $_.algo.ToLower()
            $Pool_Symbol = $_.sym.ToUpper()
            $mc = "mc=$Pool_Symbol"

            ## Wallet Swapping/Solo mining
            $Pass1 = $A_Wallets.Wallet1.Keys
            $User1 = $A_Wallets.Wallet1.$($Params.Passwordcurrency1).address
            $Pass2 = $A_Wallets.Wallet2.Keys
            $User2 = $A_Wallets.Wallet2.$($Params.Passwordcurrency2).address
            $Pass3 = $A_Wallets.Wallet3.Keys
            $User3 = $A_Wallets.Wallet3.$($Params.Passwordcurrency3).address

            if ($A_Wallets.AltWallet1.keys) {
                $A_Wallets.AltWallet1.Keys | ForEach-Object {
                    if ($A_Wallets.AltWallet1.$_.Pools -contains $P_Name) {
                        $Pass1 = $_;
                        $User1 = $A_Wallets.AltWallet1.$_.address;
                    }
                }
            }
            if ($A_Wallets.AltWallet2.keys) {
                $A_Wallets.AltWallet2.Keys | ForEach-Object {
                    if ($A_Wallets.AltWallet2.$_.Pools -contains $P_Name) {
                        $Pass2 = $_;
                        $User2 = $A_Wallets.AltWallet2.$_.address;
                    }
                }
            }
            if ($A_Wallets.AltWallet3.keys) {
                $A_Wallets.AltWallet3.Keys | ForEach-Object {
                    if ($A_Wallets.AltWallet3.$_.Pools -contains $P_Name) {
                        $Pass3 = $_;
                        $User3 = $A_Wallets.AltWallet3.$_.address;
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
                            $mc = "mc=$Sym"
                            if ($AltWallets.$Sym.address -ne "add address of coin if you wish to mine to that address, or leave alone." -and $AltWallets.$_.address -ne "") {
                                $User1 = $AltWallets.$Sym.address
                                $User2 = $AltWallets.$Sym.address
                                $User3 = $AltWallets.$Sym.address
                            }
                        }
                        if ($AltWallets.$Sym.params -ne "enter additional params here, such as 'm=solo' or m=party.partypassword") {
                            $mc += "m=$($AltWallets.$Sym.params)"
                            $mc = $mc.replace("SOLO", "solo")
                            $mc = $mc.replace("PARTY", "party")
                        }    
                    }   
                }
            }

            [Pool]::New(
                ## Symbol
                "$Pool_Symbol-Coins",
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
                "ID=$($Params.RigName1),c=$Pass1,$($mc)",
                ## Pass2
                "ID=$($Params.RigName2),c=$Pass2,$($mc)",
                ## Pass3
                "ID=$($Params.RigName3),c=$Pass3,$($mc)",
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