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

Function Global:Get-ExchangeRate {
    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    if ($(arg).CoinExchange) {
        $Uri = "https://min-api.cryptocompare.com/data/pricemulti?fsyms=$($(arg).CoinExchange)&tsyms=BTC"
        $(vars).BTCExchangeRate = Invoke-WebRequest $URI -UseBasicParsing | ConvertFrom-Json | Select-Object -ExpandProperty $(arg).CoinExchange | Select-Object -ExpandProperty "BTC"
        $Rates = @{}
        $Rates.Add("rate",$(vars).Rates.$($(arg).Currency))
        if($(vars).BTCExchangeRate){$Rates.Add("exchange",$(vars).BTCExchangeRate)}
        $Rates.Add("currency",$(arg).Currency)
        $Rates.Add("coin",$(arg).CoinExchange)
        $Rates | ConvertTo-Json | Set-Content ".\build\txt\rates.txt" -Force
    }
}

function Global:Clear-Commands {
            ## This section pulls relavant statics that users require, and then outputs them to screen or file, to be pulled on command.
            $MSFile = ".\build\txt\minerstats.txt"
            if (Test-Path $MSFIle) { Clear-Content ".\build\txt\minerstats.txt" -Force }
            $StatusDate = Get-Date
            $StatusDate | Out-File ".\build\txt\minerstats.txt"
            $StatusDate | Out-File ".\build\txt\charts.txt"    
}

function Global:Get-ScreenName {
    $(vars).Miners | ForEach-Object {
        $Miner = $_
        if ($Miner.Coin -eq $false) { $ScreenName = $Miner.Symbol }
        else {
            switch ($Miner.Symbol) {
                "GLT-PADIHASH" { $ScreenName = "GLT:PADIHASH" }
                "GLT-JEONGHASH" { $ScreenName = "GLT:JEONGHASH" }
                "GLT-ASTRALHASH" { $ScreenName = "GLT:ASTRALHASH" }
                "GLT-PAWELHASH" { $ScreenName = "GLT:PAWELHASH" }
                "GLT-SKUNK" { $ScreenName = "GLT:SKUNK" }
                "XMY-ARGON2D4096" { $ScreenName = "XMY:ARGON2D4096" }
                "ARG-ARGON2D4096" { $ScreenName = "ARG:ARGON2D4096" }
                default { $ScreenName = "$($Miner.Symbol):$($Miner.Algo)".ToUpper() }
            }
        }
        $Shares = $(vars).Share_Table.$($Miner.Type).$($Miner.MinerPool).$ScreenName.Percent -as [decimal]
        if ( $Shares -ne $null ) { $CoinShare = $Shares }else { $CoinShare = 0 }

        $Miner | Add-Member "Power_Day" ( ([Decimal]$Miner.Power * 24) / 1000 * $(vars).WattEx )
        $Miner | Add-Member "ScreenName" $ScreenName
        $Miner | Add-Member "Shares" $CoinShare
    }
}

function Global:Get-Charts {
    $Status = @()
    $Status += ""
    $Power = "|"
    $Power_Levels = @{ }
    $WattTable = $false
    $(vars).Miners | ForEach-Object { if ($_.Power_Day -ne 0) { $WattTable = $True } }

    $(arg).Type | ForEach-Object {
        $Table = $(vars).Miners | Where-Object TYPE -eq $_;
        $global:index = $Table.Count
    
        $Table | ForEach-Object { $Power_Levels.Add("$($_.ScreenName)_$($_.Miner)_$($_.MinerPool)_$($_.Type)", @{ }) }
        ##Profit Levels
        $Level = $null
        $Table | Sort-Object -Property Profit | ForEach-Object { if ($Null -ne $_.Profit) { $Profit = ($_.Profit * $(vars).Rates.$($(arg).Currency)).ToString("N2"); $MinerName = "$($_.ScreenName)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("Profit", "$Level $Profit $($(arg).Currency)/Day"); } }
        $Level = $null
        if ($(arg).CoinExchange) { $Table | Sort-Object -Property Pool_Estimate | ForEach-Object { if ($_.Pool_Estimate -gt 0) { $Profit = ($_.Pool_Estimate / $(vars).BTCExchangeRate).ToString("N5"); $MinerName = "$($_.ScreenName)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("Alt_Profit", "$Level $Profit $Y/Day"); } } }
        $Level = $null
        $Table | Sort-Object -Property Profit | ForEach-Object { if ($Null -ne $_.Profit) { $Profit = ($_.Profit).ToString("N5"); $MinerName = "$($_.ScreenName)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("BTC_Profit", "$Level $Profit BTC/Day"); } }
        $Level = $null
        $Table | Sort-Object -Property HashRates | ForEach-Object { if ($Null -ne $_.HashRates) { $HashRate = "$($_.HashRates | Global:ConvertTo-Hash)/s"; $MinerName = "$($_.ScreenName)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("Hashrate", "$Level $Hashrate"); } }
        $Level = $null
        $Table | Sort-Object -Property Shares | ForEach-Object { if ($Null -ne $_.Shares) { if ($_.Shares -eq "N/A") { $_.Shares = 0 }else { $_.Shares = $($_.Shares -as [Decimal]).ToString("N3") }; $Shares = "$($_.Shares)"; $MinerName = "$($_.ScreenName)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; if ($_.Shares -ne 0) { $Level = $Level + $Power }else { $Level = "|" }; $Power_Levels.$MinerName.Add("Shares", "$Level $Shares %"); } }
        $Level = $null
        if ($WattTable -eq $true) { $Table | Sort-Object -Property Power | ForEach-Object { if ($_.Power_Day -ne 0) { $Pwatts = ($_.Power_Day * $(vars).Rates.$($(arg).Currency)).ToString("N2"); $MinerName = "$($_.ScreenName)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("Watts", "$Level $PWatts $($(arg).Currency)/Day"); } } }
    }

    $(arg).Type | ForEach-Object {
        $Table = $(vars).Miners | Where-Object TYPE -eq $_;
        $Border_Lt = @()
        $Status += "GROUP $($_)"
        $Status += ""
    
        $Table | ForEach-Object {
            $MinerName = "$($_.ScreenName)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"
            $Border_Lt += $($Power_Levels.$MinerName.BTC_Profit | Measure-Object -Character).Characters  
        }
        $Border = $($Border_Lt | Measure-Object -Maximum).Maximum + 15
        $Table | Sort-Object -Property Profit -Descending | ForEach-Object {
            $MinerName = "$($_.ScreenName)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"
            $me = [char]27;
            $white = "37";
            $blue = "34";
            $yellow = "33";
            $green = "32";
            $cyan = "36";
            $red = "31";
            $magenta = "35";
            $HLevel = "Hashrate:"
            $HStat = if ($Null -ne $_.Hashrates) { "$me[${red};1m$($Power_Levels.$MinerName.Hashrate)${me}[0m" }else { "$me[${red};1mBenchmarking${me}[0m" }
            $CLevel = "$($(arg).Currency) Profit:"
            $CStat = if ($Null -ne $_.Profit) { "$me[${green};1m$($Power_Levels.$MinerName.Profit)${me}[0m" }else { "$me[${green};1mBenchmarking${me}[0m" }
            $BLevel = "BTC Profit:"
            $BStat = if ($Null -ne $_.Profit) { "$me[${yellow};1m$($Power_Levels.$MinerName.BTC_Profit)${me}[0m" }else { "$me[${yellow};1mBenchmarking${me}[0m" }
            if ($(arg).CoinExchange) {
                $ALevel = "$($(arg).CoinExchange) Profit:"
                $AStat = if ($_.Pool_Estimate -gt 0) { "$me[${cyan};1m$($Power_Levels.$MinerName.ALT_Profit)${me}[0m" }else { "$me[${cyan};1mBenchmarking${me}[0m" }
            }
            $SLevel = "Shares:"
            $SStat = if ($Null -ne $_.Shares) { "$me[${blue};1m$($Power_Levels.$MinerName.Shares)${me}[0m" }else { "$me[${blue};1mBenchmarking${me}[0m" }
            if ($WattTable -eq $true) {
                $Wlevel = "Watts:"
                $WStat = if ($_.Power_Day -ne 0) { "$me[${magenta};1m$($Power_Levels.$MinerName.Watts)${me}[0m" }else { "$me[${magenta};1mBenchmarking${me}[0m" }
            }
            $Table_Item = @();
            $TableName = "$me[${white};1mName: $($_.Miner)${me}[0m"; 
            $TableSymbol = "$me[${white};1mCoin: $($_.ScreenName)${me}[0m"; 
            $TablePool = "$me[${white};1mPool: $($_.MinerPool)${me}[0m"; 
            $Table_Item += "$($TableName.PadRight(40," ")) $($TableSymbol.PadRight(40," ")) $TablePool"
            $Table_Item += "".PadLeft($Border, "*")
            $Table_Item += "$me[${white};1m$($HLevel.PadRight(14))${me}[0m $HStat"
            $Table_Item += "$me[${white};1m$($CLevel.PadRight(14))${me}[0m $CStat"
            $Table_Item += "$me[${white};1m$($SLevel.PadRight(14))${me}[0m $SStat"
            $Table_Item += "$me[${white};1m$($BLevel.PadRight(14))${me}[0m $BStat"
            if ($(arg).CoinExchange) {
                $Table_Item += "$me[${white};1m$($ALevel.PadRight(14))${me}[0m $AStat"
            }
            if ($WattTable -eq $true) {
                $Table_Item += "$me[${white};1m$($WLevel.PadRight(14))${me}[0m $WStat"
            }
            $Table_Item += "".PadLeft($Border, "*")
            $Status += $Table_Item
        }
        $Status += ""
        $Status += ""
    }
    $Status
} 