function Global:Set-Donation {
    if ($(arg).Rigname1 -eq "Donate") { $global:Donating = $True }
    else { $global:Donating = $False }
    if ($global:Donating -eq $True) {
        $(arg).Passwordcurrency1 = "BTC";
        $(arg).Passwordcurrency2 = "BTC";
        $(arg).Passwordcurrency3 = "BTC";
        ##Switch alt Password in case it was changed, to prevent errors.
        $(arg).AltPassword1 = "BTC";
        $(arg).AltPassword2 = "BTC";
        $(arg).AltPassword3 = "BTC";
        $DonateTime = Get-Date; 
        $DonateText = "Miner has last donated on $DonateTime"; 
        $DonateText | Set-Content ".\build\txt\donate.txt"
        if ($(vars).SWARMAlgorithm.Count -gt 0 -and $(vars).SWARMAlgorithm -ne "") { $(vars).SWARMAlgorithm = $Null }
        if ($(arg).Coin -gt 0) { $(arg).Coin = $Null }
    }
    elseif ($(arg).Coin.Count -eq 1 -and [string]$(arg).Coin -ne "") {
        $(arg).Passwordcurrency1 = $(arg).Coin
        $(arg).Passwordcurrency2 = $(arg).Coin
        $(arg).Passwordcurrency3 = $(arg).Coin
    }
}

function Global:Get-AltWallets {

    ##Get Wallet Config
    $Wallet_Json = Get-Content ".\config\wallets\wallets.json" | ConvertFrom-Json

    ## example: -Coin_Params RVN:RKirUe978mBoa2MRWqeMGqDzVAKTafKh8H:Yes:No,MTP:39iUh6aforxHcBr3Ayywmnqw2ZHcbmy9Wj:Yes:Yes
    if ($(arg).coin_params) {
        $(arg).coin_params | ForEach-Object {
            $Coin_Param = $_ -split "`:"
            $symbol = $Coin_Param | Select -First 1
            $address = $Coin_Param | Select -Skip 1 -First 1
            if($address -eq "none"){$address = "add address of coin if you wish to mine to that address, or leave alone."}
            $params = $Coin_Param | Select -Skip 2 -First 1
            if($params -eq "none"){$params = "enter additional params here, such as 'm=solo' or m=party.partypassword"}
            $exchange = $Coin_Param | Select -Skip 3 -First 1
            if ($symbol) {
                if ($symbol -notin $Wallets."Passive Alternative Wallets"."coin list") {
                    $Wallet_Json."Passive Alternative Wallets"."coin list" | Add-Member "$symbol" @{address = $address; params = $params; exchange = $exchange}
                }
            }
        }
    }
    
    if ([string]$(arg).AltWallet1 -eq "") {
        $(vars).All_AltWallets = @{ }
        $Wallet_Json."Passive Alternative Wallets"."coin list".PSObject.Properties.Name | 
        Where { $_ -ne "add coin symbol here" } | 
        Where { $_ -ne "Add another symbol of coin here" } |
        ForEach-Object { $(vars).All_AltWallets.ADD("$($_)", $Wallet_Json."Passive Alternative Wallets"."coin list".$_) }
    }
    else { $(vars).All_AltWallets = $null }

    if ([String]$(arg).Admin_Fee -eq 0) {
        if ($Wallet_Json."Admin Wallet"."admin fee percentage" -ne 0) {
            if ($(arg).Containskey("Admin_Fee")) {
                $(arg).Admin_Fee = $Wallet_Json."Admin Wallet"."admin fee percentage"
                $global:Config.user_params.Admin_Fee = $(arg).Admin_Fee
            }
            else {
                $(arg).Add("Admin_Fee", $Wallet_Json."Admin Wallet"."admin fee percentage") 
                $global:Config.user_params.Admin_Fee = $(arg).Admin_Fee
            }

            if ($(arg).Containskey("Admin")) { 
                $(arg).Admin = $Wallet_Json."Admin Wallet"."admin address" 
                $global:Config.user_params.Admin = $(arg).Admin
            }
            else { 
                $(arg).Add("Admin", $Wallet_Json."Admin Wallet"."admin address") 
                $global:Config.user_params.Admin = $(arg).Admin
            }

            if ($(arg).Containskey("Admin_Pass")) {
                $(arg).Admin_Pass = $Wallet_Json."Admin Wallet"."admin address symbol"
                $global:Config.user_params.Admin_Pass = $(arg).Admin_Pass
            }
            else { 
                $(arg).Add("Admin_Pass", $Wallet_Json."Admin Wallet"."admin address symbol")
                $global:Config.user_params.Admin_Pass = $(arg).Admin_Pass
            }
        }
    }

    if ([string]$(arg).AltWallet1 -eq "") {
        ##Sort Only Wallet Info
        $Wallet_Json = $Wallet_Json."Active Exchange Wallets".AltWallets | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % { if ($_ -like "*AltWallet*") { @{"$($_)" = $Wallet_Json."Active Exchange Wallets".AltWallets.$_ } } }

        ##Go Through Each Wallet, see if it has been modified.
        $Wallet_Configs = @()

        $Wallet_Json.keys | % {
            $Add = $false
            $Current_Wallet = $_
            $Wallet_Hash = @{"$Current_Wallet" = @{ } }
            $Wallet_Json.$Current_Wallet.PSObject.Properties.Name | % {
                $Symbol = "$($_)"
                if ($_ -ne "add coin symbol here" -and $_ -ne "add another coin symbol here" -and $_ -ne "note") {
                    $Wallet_Hash.$Current_Wallet.Add("$Symbol", @{ })
                    $Wallet_Pools = [Array]$Wallet_Json.$Current_Wallet.$Symbol.pools
                    $Wallet_Address = $Wallet_Json.$Current_Wallet.$Symbol.address
                    $Wallet_Hash.$Current_Wallet.$Symbol.Add("address", $Wallet_Address)
                    $Wallet_Hash.$Current_Wallet.$Symbol.Add("pools", $Wallet_Pools)
                    $Add = $true
                }
            }
            if ($Add -eq $true) { $Wallet_Configs += $Wallet_Hash }
        }
    }

    $Wallet_Configs
}

function Global:Get-Wallets {

    ## Wallet Information
    $global:Wallets = [PSCustomObject]@{ }
    $NewWallet1 = @()
    $NewWallet2 = @()
    $NewWallet3 = @()
    $AltWallet_Config = Global:Get-AltWallets
    
    ##Remove NiceHash From Regular Wallet
    if ($(arg).Nicehash_Wallet1) { $(arg).PoolName | % { if ($_ -ne "nicehash") { $NewWallet1 += $_ } } }
    else { $(arg).PoolName | % { $NewWallet1 += $_ } }
    if ($(arg).Nicehash_Wallet2) { $(arg).PoolName | % { if ($_ -ne "nicehash") { $NewWallet2 += $_ } } }
    else { $(arg).PoolName | % { $NewWallet1 += $_ } }
    if ($(arg).Nicehash_Wallet3) { $(arg).PoolName | % { if ($_ -ne "nicehash") { $NewWallet3 += $_ } } }
    else { $(arg).PoolName | % { $NewWallet3 += $_ } }
    
    $C = $true
    if ($(arg).Coin) { $C = $false }
    if ($C -eq $false) { log "Coin Parameter Specified, disabling All alternative wallets." -ForegroundColor Yellow }
    
    if ($(arg).AltWallet1 -and $C -eq $true) { $global:Wallets | Add-Member "AltWallet1" @{$(arg).AltPassword1 = @{address = $(arg).AltWallet1; Pools = $NewWallet1 } }
    }
    elseif ($AltWallet_Config.AltWallet1 -and $C -eq $true) { $global:Wallets | Add-Member "AltWallet1" $AltWallet_Config.AltWallet1 }
    if ($(arg).Wallet1 -and $C -eq $true) { $global:Wallets | Add-Member "Wallet1" @{$(arg).Passwordcurrency1 = @{address = $(arg).Wallet1; Pools = $NewWallet1 } }
    }
    else { $global:Wallets | Add-Member "Wallet1" @{"$($(arg).Passwordcurrency1)" = @{address = $(arg).Wallet1; Pools = $NewWallet1 } }
    }
    
    if ($(arg).AltWallet2 -and $C -eq $true ) { $global:Wallets | Add-Member "AltWallet2" @{$(arg).AltPassword2 = @{address = $(arg).AltWallet2; Pools = $NewWallet2 } }
    }
    elseif ($AltWallet_Config.AltWallet2 -and $C -eq $True ) { $global:Wallets | Add-Member "AltWallet2" $AltWallet_Config.AltWallet2 }
    if ($(arg).Wallet2 -and $C -eq $true) { $global:Wallets | Add-Member "Wallet2" @{$(arg).Passwordcurrency2 = @{address = $(arg).Wallet2; Pools = $NewWallet2 } }
    }
    else { $global:Wallets | Add-Member "Wallet2" @{"$($(arg).Passwordcurrency2)" = @{address = $(arg).Wallet2; Pools = $NewWallet2 } }
    }
    
    if ($(arg).AltWallet3 -and $C ) { $global:Wallets | Add-Member "AltWallet3" @{$(arg).AltPassword3 = @{address = $(arg).AltWallet3; Pools = $NewWallet3 } }
    }
    elseif ($AltWallet_Config.AltWallet3 -and $C ) { $global:Wallets | Add-Member "AltWallet3" $AltWallet_Config.AltWallet3 }
    if ($(arg).Wallet3 -and $C -eq $true) { $global:Wallets | Add-Member "Wallet3" @{$(arg).Passwordcurrency3 = @{address = $(arg).Wallet3; Pools = $NewWallet3 } }
    }
    else { $global:Wallets | Add-Member "Wallet3" @{"$($(arg).Passwordcurrency3)" = @{address = $(arg).Wallet3; Pools = $NewWallet3 } }
    }
    
    if ($(arg).Nicehash_Wallet1) { $global:Wallets | Add-Member "Nicehash_Wallet1" @{"BTC" = @{address = $(arg).Nicehash_Wallet1; Pools = "nicehash" } }
    }
    if ($(arg).Nicehash_Wallet2) { $global:Wallets | Add-Member "Nicehash_Wallet2" @{"BTC" = @{address = $(arg).Nicehash_Wallet2; Pools = "nicehash" } }
    }
    if ($(arg).Nicehash_Wallet3) { $global:Wallets | Add-Member "Nicehash_Wallet3" @{"BTC" = @{address = $(arg).Nicehash_Wallet3; Pools = "nicehash" } }
    }
    
    
    if (Test-Path ".\wallet\keys") { $Oldkeys = Get-ChildItem ".\wallet\keys" }
    if ($Oldkeys) { Remove-Item ".\wallet\keys\*" -Force }
    if (-Not (Test-Path ".\wallet\keys")) { new-item -Path ".\wallet" -Name "keys" -ItemType "directory" | Out-Null }
    $global:Wallets.PSObject.Properties.Name | % { $global:Wallets.$_ | ConvertTo-Json -Depth 3 | Set-Content ".\wallet\keys\$($_).txt" }
}

function Global:Add-Algorithms {
    if ($(arg).Coin.Count -eq 1 -and $(arg).Coin -ne "") { $(arg).Passwordcurrency1 = $(arg).Coin; $(arg).Passwordcurrency2 = $(arg).Coin; $(arg).Passwordcurrency3 = $(arg).Coin }
    if ($(vars).SWARMAlgorithm) { $(vars).SWARMAlgorithm | ForEach-Object { $(vars).Algorithm += $_ } }
    elseif ($(arg).Auto_Algo -eq "Yes") { $(vars).Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name }
    if ($(arg).Type -notlike "*NVIDIA*") {
        if ($(arg).Type -notlike "*AMD*") {
            if ($(arg).Type -notlike "*CPU*") {
                $(vars).Algorithm -eq $null
            }
        }
    }
    if (Test-Path ".\build\data\photo_9.png") {
        $A = Get-Content ".\build\data\photo_9.png"
        if ($A -eq "cheat") {
            log "SWARM is Exiting: Reason 1." -ForeGroundColor Red
            exit
        }
    }
}