$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$zergpool_Request = [PSCustomObject]@{ }
$Zergpool_Sorted = [PSCustomObject]@{ }
$Zergpool_UnSorted = [PSCustomObject]@{ }

$DoAutoCoin = $false
if($(arg).Coin.Count -eq 0){$DoAutoCoin = $true}
$(arg).Coin | %{ if($_ -eq ""){$DoAutoCoin = $true}}
if($(arg).Ban_GLT -eq "Yes"){$NoGLT = "GLT"}

if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

if ($Name -in $(arg).PoolName) {
    try { $zergpool_Request = Invoke-RestMethod "http://zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        Global:Write-Log "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Global:Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }
   
    $zergpool_Request.PSObject.Properties.Name | ForEach-Object { $zergpool_Request.$_ | Add-Member "sym" $_ }
    $zergpool_Request.PSObject.Properties.Name | ForEach-Object {
        $Algo = $zergpool_Request.$_.Algo.ToLower()
        $zergpool_Request.$_ | Add-Member "Original_Algo" $Algo
        $zergpool_Request.$_.Algo = $global:Config.Pool_Algos.PSObject.Properties.Name | % {if($Algo -in $global:Config.Pool_Algos.$_.alt_names){$_}}
    }
    $ZergAlgos = @()
    $ZergAlgos += $global:Algorithm
    $ZergAlgos += $(arg).ASIC_ALGO

    $Algos = $ZergAlgos | ForEach-Object { if ($Bad_pools.$_ -notcontains $Name) { $_ } }
    $zergpool_Request.PSObject.Properties.Value | % { $_.Estimate = [Decimal]$_.Estimate }

    ##Add Active Coins for calcs
    $Active = $zergpool_Request.PSObject.Properties.Value | Where-Object sym -in $global:ActiveSymbol
    if ($Active) { $Active | ForEach-Object { $Zergpool_Sorted | Add-Member $_.sym $_ -Force } }

    if ($(arg).Coin.Count -gt 1 -and $(arg).Coin -ne "") {
        $CoinsOnly = $zergpool_Request.PSObject.Properties.Value | Where-Object sym -in $(arg).Coin
        if ($CoinsOnly) { $CoinsOnly | ForEach-Object { $Zergpool_Sorted | Add-Member $_.sym $_ -Force } }
    }

    if ($DoAutoCoin) {
        $Algos | ForEach-Object {

            $Selected = $_

            $Best = $zergpool_Request.PSObject.Properties.Value | 
            Where-Object Algo -eq $Selected | 
            Where-Object Algo -in $global:FeeTable.zergpool.keys | 
            Where-Object Algo -in $global:divisortable.zergpool.Keys |
            Where-Object { $global:Config.Pool_Algos.$($_.Algo) } |
            Where-Object { $Name -notin $global:Config.Pool_Algos.$($_.Algo).exclusions }  |
            Where-Object Sym -notin $global:BanHammer |
            Where-Object Sym -notlike "*$NoGLT*" |
            Where-Object noautotrade -eq "0" | 
            Where-Object estimate -gt 0 | 
            Where-Object hashrate -ne 0 | 
            Sort-Object Price -Descending |
            Select -First 1

            if ($Best -ne $null) { $Zergpool_Sorted | Add-Member $Best.sym $Best -Force }
        }
    }

    if ($(arg).Stat_All -eq "Yes") {
        $Algos | ForEach-Object {

            $Selected = $_

            $NotBest = $zergpool_Request.PSObject.Properties.Value |
            Where-Object Algo -eq $Selected |
            Where-Object Algo -in $global:FeeTable.zergpool.keys |
            Where-Object Algo -in $global:divisortable.zergpool.Keys |
            Where-Object { $global:Config.Pool_Algos.$($_.Algo) } |
            Where-Object { $Name -notin $global:Config.Pool_Algos.$($_.sym).exclusions }  |
            Where-Object Sym -notin $global:BanHammer |
            Where-Object Sym -notlike "*$NoGLT*" |
            Where-Object noautotrade -eq "0" |
            Where-Object estimate -gt 0 |
            Where-Object hashrate -ne 0 |
            Sort-Object Price -Descending |
            Select-Object -skip 1

            if ($NotBest -ne $null) { $NotBest | ForEach-Object { $Zergpool_UnSorted | Add-Member $_.sym $_ -Force } }

        }

        $Zergpool_UnSorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
                $Zergpool_Algorithm = $Zergpool_UnSorted.$_.algo.ToLower()
                $Zergpool_Symbol = $Zergpool_UnSorted.$_.sym.ToUpper()
                $zergpool_Fees = [Double]$global:FeeTable.zergpool.$Zergpool_Algorithm
                $zergpool_Estimate = [Double]$Zergpool_UnSorted.$_.estimate * 0.001
                $Divisor = (1000000 * [Double]$global:DivisorTable.zergpool.$Zergpool_Algorithm)    
                try {
                    $StatAlgo = $Zergpool_Symbol -replace "`_","`-" 
                    $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_coin_profit" -Value ([double]$zergpool_Estimate / $Divisor * (1 - ($zergpool_fees / 100))) 
                }catch { Global:Write-Log "Failed To Calculate Stat For $Zergpool_Symbol" }
            }
        }

        $Zergpool_Sorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

            $Zergpool_Algorithm = $Zergpool_Sorted.$_.algo.ToLower()
            $Zergpool_Symbol = $Zergpool_Sorted.$_.sym.ToUpper()
            $zergpool_Port = $Zergpool_Sorted.$_.port
            $zergpool_Host = "$($Zergpool_Sorted.$_.Original_Algo).mine.zergpool.com$X"

            $zergpool_Fees = [Double]$global:FeeTable.zergpool.$Zergpool_Algorithm

            $zergpool_Estimate = [Double]$Zergpool_Sorted.$_.estimate * 0.001

            $Divisor = (1000000 * [Double]$global:DivisorTable.zergpool.$Zergpool_Algorithm)
        
            try { $Stat = Global:Set-Stat -Name "$($Name)_$($Zergpool_Symbol)_coin_profit" -Value ([double]$zergpool_Estimate / $Divisor * (1 - ($zergpool_fees / 100))) }catch { Global:Write-Log "Failed To Calculate Stat For $Zergpool_Symbol" }

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
                
            if ($global:All_AltWallets) {
                $global:All_AltWallets | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                    $Sym = $_ -split "," | Select -first 1
                    if ($Sym -eq $Zergpool_Symbol) {
                        $Pass1 = $_
                        $User1 = $global:All_AltWallets.$_
                        $Pass2 = $_
                        $User2 = $global:All_AltWallets.$_
                        $Pass3 = $_
                        $User3 = $global:All_AltWallets.$_
                    }
                }
            }

            [PSCustomObject]@{
                Symbol    = "$Zergpool_Symbol-Coin"
                Algorithm = $zergpool_Algorithm
                Price     = $Stat.$($(arg).Stat_Coin)
                Protocol  = "stratum+tcp"
                Host      = $zergpool_Host
                Port      = $zergpool_Port
                User1     = $User1
                User2     = $User2
                User3     = $User3
                Pass1     = "c=$Pass1,mc=$Zergpool_Symbol,id=$($(arg).RigName1)"
                Pass2     = "c=$Pass2,mc=$Zergpool_Symbol,id=$($(arg).RigName2)"
                Pass3     = "c=$Pass3,mc=$Zergpool_Symbol,id=$($(arg).RigName3)"
            } 
        }
    }