function Set-Donation {
    if ($global:config.params.Rigname1 -eq "Donate") { $global:Donating = $True }
    else { $global:Donating = $False }
    if ($global:Donating -eq $True) {
        $global:Config.Params.Passwordcurrency1 = "BTC";
        $global:Config.Params.Passwordcurrency2 = "BTC";
        $global:Config.Params.Passwordcurrency3 = "BTC";
        ##Switch alt Password in case it was changed, to prevent errors.
        $global:Config.Params.AltPassword1 = "BTC";
        $global:Config.Params.AltPassword2 = "BTC";
        $global:Config.Params.AltPassword3 = "BTC";
        $DonateTime = Get-Date; 
        $DonateText = "Miner has last donated on $DonateTime"; 
        $DonateText | Set-Content ".\build\txt\donate.txt"
        if ($global:SWARMAlgorithm.Count -gt 0 -and $global:SWARMAlgorithm -ne "") { $global:SWARMAlgorithm = $Null }
        if ($global:Config.Params.Coin -gt 0) { $global:Config.Params.Coin = $Null }
    }
    elseif ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "") {
        $global:Config.Params.Passwordcurrency1 = $global:Config.Params.Coin
        $global:Config.Params.Passwordcurrency2 = $global:Config.Params.Coin
        $global:Config.Params.Passwordcurrency3 = $global:Config.Params.Coin
    }
}

function Get-AltWallets {

    ##Get Wallet Config
    $Wallet_Json = Get-Content ".\config\wallets\wallets.json" | ConvertFrom-Json
    
    if(-not $global:Config.Params.AltWallet1){$Global:All_AltWallets = $Wallet_Json.All_AltWallets}

    ##Sort Only Wallet Info
    $Wallet_Json = $Wallet_Json | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {if ($_ -like "*AltWallet*") {@{"$($_)" = $Wallet_Json.$_}}}

    ##Go Through Each Wallet, see if it has been modified.
    $Wallet_Configs = @()

    $Wallet_Json.keys | % {
        $Add = $false
        $Current_Wallet = $_
        $Wallet_Hash = @{"$Current_Wallet" = @{}}
        $Wallet_Json.$Current_Wallet.PSObject.Properties.Name | % {
            $Symbol = "$($_)"
            if ($_ -ne "add coin symbol here") {
                if ($_ -ne "add another coin symbol here") {
                    $Wallet_Hash.$Current_Wallet.Add("$Symbol", @{})
                    $Wallet_Pools = [Array]$Wallet_Json.$Current_Wallet.$Symbol.pools
                    $Wallet_Address = $Wallet_Json.$Current_Wallet.$Symbol.address
                    $Wallet_Hash.$Current_Wallet.$Symbol.Add("address", $Wallet_Address)
                    $Wallet_Hash.$Current_Wallet.$Symbol.Add("pools", $Wallet_Pools)
                    $Add = $true
                }
            }
        }
        if($Add -eq $true){$Wallet_Configs += $Wallet_Hash}
    }

    $Wallet_Configs
}

function Get-Wallets {

    ## Wallet Information
    $global:Wallets = [PSCustomObject]@{ }
    $NewWallet1 = @()
    $NewWallet2 = @()
    $NewWallet3 = @()
    $AltWallet_Config = Get-AltWallets
    
    ##Remove NiceHash From Regular Wallet
    if ($global:Config.Params.Nicehash_Wallet1) { $global:Config.Params.PoolName | % { if ($_ -ne "nicehash") { $NewWallet1 += $_ } } }
    else { $global:Config.Params.PoolName | % { $NewWallet1 += $_ } }
    if ($global:Config.Params.Nicehash_Wallet2) { $global:Config.Params.PoolName | % { if ($_ -ne "nicehash") { $NewWallet2 += $_ } } }
    else { $global:Config.Params.PoolName | % { $NewWallet1 += $_ } }
    if ($global:Config.Params.Nicehash_Wallet3) { $global:Config.Params.PoolName | % { if ($_ -ne "nicehash") { $NewWallet3 += $_ } } }
    else { $global:Config.Params.PoolName | % { $NewWallet3 += $_ } }
    
    $C = $true
    if ($global:Config.Params.Coin) { $C = $false }
    if ($C -eq $false) { write-log "Coin Parameter Specified, disabling All alternative wallets." -ForegroundColor Yellow }
    
    if ($global:Config.Params.AltWallet1 -and $C -eq $true) { $global:Wallets | Add-Member "AltWallet1" @{$global:Config.Params.AltPassword1 = @{address = $global:Config.Params.AltWallet1; Pools = $NewWallet1 } }
    }
    elseif ($AltWallet_Config.AltWallet1 -and $C -eq $true) { $global:Wallets | Add-Member "AltWallet1" $AltWallet_Config.AltWallet1 }
    if ($global:Config.Params.Wallet1 -and $C -eq $true) { $global:Wallets | Add-Member "Wallet1" @{$global:Config.Params.Passwordcurrency1 = @{address = $global:Config.Params.Wallet1; Pools = $NewWallet1 } }
    }
    else { $global:Wallets | Add-Member "Wallet1" @{$global:Config.Params.Passwordcurrency1 = @{address = $global:Config.Params.Wallet1; Pools = $NewWallet1 } }
    }
    
    if ($global:Config.Params.AltWallet2 -and $C -eq $true ) { $global:Wallets | Add-Member "AltWallet2" @{$global:Config.Params.AltPassword2 = @{address = $global:Config.Params.AltWallet2; Pools = $NewWallet2 } }
    }
    elseif ($AltWallet_Config.AltWallet2 -and $C -eq $True ) { $global:Wallets | Add-Member "AltWallet2" $AltWallet_Config.AltWallet2 }
    if ($global:Config.Params.Wallet2 -and $C -eq $true) { $global:Wallets | Add-Member "Wallet2" @{$global:Config.Params.Passwordcurrency2 = @{address = $global:Config.Params.Wallet2; Pools = $NewWallet2 } }
    }
    else { $global:Wallets | Add-Member "Wallet2" @{$global:Config.Params.Passwordcurrency2 = @{address = $global:Config.Params.Wallet2; Pools = $NewWallet2 } }
    }
    
    if ($global:Config.Params.AltWallet3 -and $C ) { $global:Wallets | Add-Member "AltWallet3" @{$global:Config.Params.AltPassword3 = @{address = $global:Config.Params.AltWallet3; Pools = $NewWallet3 } }
    }
    elseif ($AltWallet_Config.AltWallet3 -and $C ) { $global:Wallets | Add-Member "AltWallet3" $AltWallet_Config.AltWallet3 }
    if ($global:Config.Params.Wallet3 -and $C -eq $true) { $global:Wallets | Add-Member "Wallet3" @{$global:Config.Params.Passwordcurrency3 = @{address = $global:Config.Params.Wallet3; Pools = $NewWallet3 } }
    }
    else { $global:Wallets | Add-Member "Wallet3" @{$global:Config.Params.Passwordcurrency3 = @{address = $global:Config.Params.Wallet3; Pools = $NewWallet3 } }
    }
    
    if ($global:Config.Params.Nicehash_Wallet1) { $global:Wallets | Add-Member "Nicehash_Wallet1" @{"BTC" = @{address = $global:Config.Params.Nicehash_Wallet1; Pools = "nicehash" } }
    }
    if ($global:Config.Params.Nicehash_Wallet2) { $global:Wallets | Add-Member "Nicehash_Wallet2" @{"BTC" = @{address = $global:Config.Params.Nicehash_Wallet2; Pools = "nicehash" } }
    }
    if ($global:Config.Params.Nicehash_Wallet3) { $global:Wallets | Add-Member "Nicehash_Wallet3" @{"BTC" = @{address = $global:Config.Params.Nicehash_Wallet3; Pools = "nicehash" } }
    }
    
    
    if (Test-Path ".\wallet\keys") { $Oldkeys = Get-ChildItem ".\wallet\keys" }
    if ($Oldkeys) { Remove-Item ".\wallet\keys\*" -Force }
    if (-Not (Test-Path ".\wallet\keys")) { new-item -Path ".\wallet" -Name "keys" -ItemType "directory" | Out-Null }
    $global:Wallets.PSObject.Properties.Name | % { $global:Wallets.$_ | ConvertTo-Json -Depth 3 | Set-Content ".\wallet\keys\$($_).txt" }
}

function Add-Algorithms {
    if ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "") { $global:Config.Params.Passwordcurrency1 = $global:Config.Params.Coin; $global:Config.Params.Passwordcurrency2 = $global:Config.Params.Coin; $global:Config.Params.Passwordcurrency3 = $global:Config.Params.Coin }
    if ($global:SWARMAlgorithm) { $global:SWARMAlgorithm | ForEach-Object { $global:Algorithm += $_ } }
    elseif ($global:Config.Params.Auto_Algo -eq "Yes") { $global:Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name }
    if ($global:Config.Params.Type -notlike "*NVIDIA*") {
        if ($global:Config.Params.Type -notlike "*AMD*") {
            if ($global:Config.Params.Type -notlike "*CPU*") {
                $global:Algorithm -eq $null
            }
        }
    }
    if (Test-Path ".\build\data\photo_9.png") {
        $A = Get-Content ".\build\data\photo_9.png"
        if ($A -eq "cheat") {
            Write-Log "SWARM is Exiting: Reason 1." -ForeGroundColor Red
            exit
        }
    }
}