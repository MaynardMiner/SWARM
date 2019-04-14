function Get-AhashpoolData {
    $Wallets = @()
    $Type | ForEach-Object {
        $Sel = $_
        $Pool = "ahashpool"
        $global:Share_Table.$Sel.Add($Pool, @{ })
        $User_Wallet = $($Miners | Where-Object Type -eq $Sel | Where-Object MinerPool -eq $Pool | Select-Object -Property Wallet -Unique).Wallet
        if ($Wallets -notcontains $User_Wallet) { try { $HTML = Invoke-WebRequest -Uri "https://www.ahashpool.com/wallet_wallet_miners_results.php?wallet=$User_Wallet&showdetails=1" -TimeoutSec 5 -ErrorAction Stop }catch { Write-Warning "Failed to get Shares from $Pool" } }
        $Wallets += $User_Wallet
        $string = $HTML.Content
        $string = $string -split "class=`"ssrow`"><td><b>"
        $string = $string -split "</table><br><table"
        $string = $string | ForEach-Object { if ($_ -like "*%*" -and $_ -notlike "*dataGrid2*") { $_ } }
        $Test
        $Test
        $Test
        if ($string) {
            $string | ForEach-Object {
                $Cur = $_
                $CoinName = $Cur -split "</b></td><td align=" | Select-Object -First 1;
                $Algo = $CoinName
                $Percent = $Cur -split "width=`"100`">" | ForEach-Object { if ($_ -like "*%*") { $_ } }
                $Percent = $Percent -split "%" | Select-Object -First 1
                try { if ([Double]$Percent -gt 0) { $SPercent = $Percent }else { $SPercent = 0 } }catch { Write-Warning "A Share Value On Site Could Not Be Read on $Pool" }
                $Symbol = $Algo.ToLower()
                $global:Share_Table.$Sel.$Pool.Add($Symbol, @{ })
                $global:Share_Table.$Sel.$Pool.$Symbol.Add("Name", $CoinName)
                $global:Share_Table.$Sel.$Pool.$Symbol.Add("Percent", $SPercent)
                $global:Share_Table.$Sel.$Pool.$Symbol.Add("Algo", $Algo)
            }
        }
    }
}