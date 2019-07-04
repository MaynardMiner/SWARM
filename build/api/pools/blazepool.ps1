function Global:Get-BlazepoolData {
    $Wallets = @()
    $(arg).Type | ForEach-Object {
        $Sel = $_
        $Pool = "blazepool"
        $(vars).Share_Table.$Sel.Add($Pool, @{ })
        $User_Wallet = $($(vars).Miners | Where-Object Type -eq $Sel | Where-Object MinerPool -eq $Pool | Select-Object -Property Wallet -Unique).Wallet
        if ($Wallets -notcontains $User_Wallet) { try { $HTML = Invoke-RestMethod -Uri "http://api.blazepool.com/data/$User_Wallet" -TimeoutSec 10 -ErrorAction Stop }catch { log "Failed to get Shares from $Pool" } }
        $sum = $HTML.summary
        if ($sum) {
            $sum | ForEach-Object {
                $Algo = $_.algo
                $CoinName = $_.algo
                $Percent = $_.Share
                try { if ([Double]$Percent -gt 0) { $SPercent = $Percent -as [decimal] }else { $SPercent = 0 } }catch { log "A Share Value On Site Could Not Be Read on $Pool" }
                $Symbol = $Algo.ToLower()
                $(vars).Share_Table.$Sel.$Pool.Add($Symbol, @{ })
                $(vars).Share_Table.$Sel.$Pool.$Symbol.Add("Name", $CoinName)
                $(vars).Share_Table.$Sel.$Pool.$Symbol.Add("Percent", $SPercent)
                $(vars).Share_Table.$Sel.$Pool.$Symbol.Add("Algo", $Algo)
            }
        }
    }
}