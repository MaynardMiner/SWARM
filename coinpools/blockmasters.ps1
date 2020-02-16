Using namespace System;

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 

$block_request = [PSCustomObject]@{ }
$block_sorted = [PSCustomObject]@{ }

if ($(arg).Ban_GLT -eq "Yes") { $NoGLT = "GLT" }
else { $NOGLT = "SWARM1234" } ## Just a placeholder, can't equal GLT.
if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

if ($Name -in $(arg).PoolName) {

    try { $block_request = Invoke-RestMethod "http://blockmasters.co/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        log "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($block_request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }
   
    ## Add symbol to the list for sorting
    $block_request.PSObject.Properties.Name | ForEach-Object { $block_request.$_ | Add-Member "sym" $_ }

    ## Convert to universal naming schema
    $block_request.PSObject.Properties.Name | ForEach-Object {
        $Algo = $block_request.$_.Algo.ToLower()
        $block_request.$_ | Add-Member "Original_Algo" $Algo
        $block_request.$_.Algo = $global:Config.Pool_Algos.PSObject.Properties.Name | % { if ($Algo -in $global:Config.Pool_Algos.$_.alt_names) { $_ } }
    }

    
    # Make an algo list, include asic algorithms not usually in SWARM
    ## Remove algos that users/SWARM have banned.
    $BlockAlgos = @()
    $BlockAlgos += $(vars).Algorithm
    $BlockAlgos += $(arg).ASIC_ALGO
    $Algos = $BlockAlgos | ForEach-Object { if ($Bad_pools.$_ -notcontains $Name) { $_ } }

    $block_request.PSObject.Properties.Value | ForEach-Object { $_.Estimate = [Decimal]$_.Estimate }

    ## Automatically add Active Coins for calcs. Active Coins are coins that are currently being mined.
    $Active = $block_request.PSObject.Properties.Value | Where-Object sym -in $(vars).ActiveSymbol
    if ($Active) { $Active | ForEach-Object { $block_sorted | Add-Member $_.sym $_ -Force } }

    if ($(arg).Coin.Count -gt 1 -and $(arg).Coin -ne "") {
        $CoinsOnly = $block_request.PSObject.Properties.Value | Where-Object sym -in $(arg).Coin
        if ($CoinsOnly) { $CoinsOnly | ForEach-Object { $block_sorted | Add-Member $_.sym $_ -Force } }
    }
    else {
        $Algos | ForEach-Object {
            $Selected = $_
            $block_request.PSObject.Properties.Value | 
            Where-Object Algo -eq $Selected |
            Where-Object Algo -in $(vars).FeeTable.blockmasters.keys | 
            Where-Object Algo -in $(vars).divisortable.blockmasters.Keys |
            Where-Object { $global:Config.Pool_Algos.$($_.Algo) } |
            Where-Object { $Name -notin $global:Config.Pool_Algos.$($_.Algo).exclusions } |
            Where-Object Sym -notin $(vars).BanHammer |
            Where-Object { $_.Sym -notin $global:Config.Pool_Algos.$($_.Algo).exclusions } |
            Where-Object Sym -notlike "*$NoGLT*" |
            Where-Object estimate -gt 0 |
            ForEach-Object { $block_sorted | Add-Member $_.sym $_ -Force }
        }
    }

    $block_sorted | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $Blockpool_Algo = $block_sorted.$_.algo.ToLower()
        $Blockpool_Symbol = $block_sorted.$_.sym.ToUpper()
        $StatAlgo = $Blockpool_Symbol -replace "`_", "`-" 
        $Divisor = 1000000 * [Convert]::ToDouble($(vars).divisortable.blockmasters.$Blockpool_Algo)
        $Blockpool_Fees = [Convert]::ToDouble($(vars).FeeTable.blockmasters.$Blockpool_Algo)
        $Blockpool_Estimate = [Convert]::ToDouble($block_sorted.$_.estimate * 0.001)
        $StatPath = "$($Name)_$($StatAlgo)_coin_profit"
        $Hashrate = [convert]::ToDouble($block_sorted.$_.hashrate)
        $Stat = Global:Set-Stat -Name $StatPath -HashRate $HashRate -Value ($Blockpool_Estimate / $Divisor * (1 - ($Blockpool_fees / 100)))
        $Level = $Stat.$($(arg).Stat_Algo)
        $block_sorted.$_ | Add-Member "Level" $Level 
    }

    $Algos | ForEach-Object {
        $Selected = $_

        $block_sorted.PSObject.Properties.Value | 
        Where-Object Algo -eq $Selected | 
        Where-Object { [Convert]::Int32($_."24h_blocks") -ge $(arg).Min_Blocks } |
        Where-Object { if([string]$(arg).coin -ne "") { $_.sym -in $(arg).coin } else{$_} } |
        Sort-Object Level -Descending | 
        Select-Object -First 1 | 
        ForEach-Object { 

            $Blockpool_Algo = $_.algo.ToLower()
            $Blockpool_Symbol = $_.sym.ToUpper()
            $mc = "mc=$Blockpool_Symbol,"
            $Blockpool_Port = $_.port
            $Blockpool_Host = "blockmasters.co$X"
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
                    $Block_Sym = $Blockpool_Symbol -split "-" | Select -First 1
                    if ($Sym -eq $Block_Sym -or $Sym -eq $Blockpool_Symbol) {
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
                            $mc = $mc.replace("solo","SOLO")
                            $mc = $mc.replace("party","PARTY")
                        }    
                    }   
                }
            }

            [Pool]::New(
                ## Symbol
                "$BlockPool_Symbol-Coin",
                ## Algorithm
                $Blockpool_Algo,
                ## Level
                $_.Level,
                ## Stratum
                "stratum+tcp",
                ## Pool_Host
                $Blockpool_Host,
                ## Pool_Port
                $Blockpool_Port,
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

