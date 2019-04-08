function Get-ZergpoolData {
    $Wallets = @()

    $Type | % {
        $Sel = $_
        $Pool = "zergpool"
        $global:Share_Table.$Sel.Add($Pool,@{})
        $User_Wallet = $($Miners | Where Type -eq $Sel | Where MinerPool -eq $Pool | Select -Property Wallet -Unique).Wallet
        if ($Wallets -notcontains $User_Wallet) {try {$HTML = Invoke-WebRequest -Uri "http://www.zergpool.com/site/wallet_miners_results?address=$User_Wallet" -TimeoutSec 5 -ErrorAction Stop}catch {Write-Warning "Failed to get Shares from $Pool"}}
        $Wallets += $User_Wallet
        $string = $HTML.Content
        $string = $string -split "src=`"/images/"
        $string = $string -split "</table><br><table"
        $string = $string | % {if ($_ -like "*</b><span style=*") {$_}}
        if($String)
         {
        $string | % {
            $Cur = $_
            $Algo = $Cur -split ".8em;`"> \(" | Select -Last 1;
            $Algo = $Algo -split "\)</span><td" | Select -First 1
            $CoinName = $Cur -split ".png" | Select -First 1;
            $Percent = $Cur -split "width=`"60`">" | % {if ($_ -like "*%*") {$_}}
            $Percent = $Percent -split "%" | Select -First 1
            try{if ([Double]$Percent -gt 0) {$SPercent = $Percent}else {$SPercent = 0}}catch{Write-Warning "A Share Value On Site Could Not Be Read on $Pool"}
            $Symbol = "$CoinName`:$Algo".ToUpper()
            $global:Share_Table.$Sel.$Pool.Add($Symbol,@{})
            $global:Share_Table.$Sel.$Pool.$Symbol.Add("Name", $CoinName)
            $global:Share_Table.$Sel.$Pool.$Symbol.Add("Percent", $SPercent)
            $global:Share_Table.$Sel.$Pool.$Symbol.Add("Algo", $Algo)
        }
      }
    }
}