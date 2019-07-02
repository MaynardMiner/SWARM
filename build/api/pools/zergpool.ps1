function Global:Get-ZergpoolData {
    $Wallets = @()

    $(arg).Type | ForEach-Object {
        $Sel = $_
        $Pool = "zergpool"
        $(vars).Share_Table.$Sel.Add($Pool, @{ })
        $User_Wallet = $($(vars).Miners | Where-Object Type -eq $Sel | Where-Object MinerPool -eq $Pool | Select-Object -Property Wallet -Unique).Wallet
        if ($Wallets -notcontains $User_Wallet) { try { $HTML = Invoke-WebRequest -Uri "http://www.zergpool.com/site/wallet_miners_results?address=$User_Wallet" -TimeoutSec 10 -ErrorAction Stop }catch { Global:Write-Log "Failed to get Shares from $Pool" } }
        $Wallets += $User_Wallet
        $string = $HTML.Content
        $string = $string -split "src=`"/images/"
        $string = $string -split "</table><br><table"
        $string = $string | ForEach-Object { if ($_ -like "*</b><span style=*") { $_ } }
        if ($String) {
            $string | ForEach-Object {
                $Cur = $_
                $Algo = $Cur -split ".8em;`"> \(" | Select-Object -Last 1;
                $Algo = $Algo -split "\)</span><td" | Select-Object -First 1
                $CoinName = $Cur -split ".png" | Select-Object -First 1;
                $Percent = $Cur -split "width=`"60`">" | ForEach-Object { if ($_ -like "*%*") { $_ } }
                $Percent = $Percent -split "%" | Select-Object -First 1
                try { if ([Double]$Percent -gt 0) { $SPercent = $Percent }else { $SPercent = 0 } }catch { Global:Write-Log "A Share Value On Site Could Not Be Read on $Pool" }
                $Symbol = "$CoinName`:$Algo".ToUpper()
                $(vars).Share_Table.$Sel.$Pool.Add($Symbol, @{ })
                $(vars).Share_Table.$Sel.$Pool.$Symbol.Add("Name", $CoinName)
                $(vars).Share_Table.$Sel.$Pool.$Symbol.Add("Percent", $SPercent)
                $(vars).Share_Table.$Sel.$Pool.$Symbol.Add("Algo", $Algo)
            }
        }
    }
}