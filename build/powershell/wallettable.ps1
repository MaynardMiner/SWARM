function Get-WalletTable {

$WalletTable = @()
if(Test-Path ".\wallet\pools"){Get-ChildItemContent ".\wallet\pools"}
if(-not $GetWStats){$GetWStats = get-wstats}
if(-not $Wallet1){if(Test-Path ".\wallet\wallets\wallets.txt"){$Walletlist = Get-Content ".\wallet\wallets\wallets.txt" | ConvertFrom-Json}}

$WalletList | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | %{
 $SelectedName = $_
 $Selected = $Walletlist.$_
  $GetWStats.PSObject.Properties.Name | %{
   if($GetWStats.$_.address -eq $Selected)
    {
      $WalletTable += [PSCustomObject]@{
      Wallet = $SelectedName
      Address = $Selected
      Pool = $GetWStats.$_.Pool
      Ticker = $GetWStats.$_.Symbol
      Unpaid = $GetWStats.$_.Unpaid
      Balance = $GetWStats.$_.Balance
      "Last Checked" = $GetWStats.$_.Date
     }
    }
  }
 }

$SortTable = @()

$WalletList | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | %{ 
  $Sort = $WalletTable | Where Wallet -eq $_
  $SortTable += [PSCustomObject]@{$_ = $Sort}
}

$Wallet_Table = @()

$WalletList | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | %{
  $Pools = @()
  $Sel = $_
  $SortTable.$Sel | Foreach {
   if($_.Pool)
    {
      $Pools += [PSCustomObject]@{
       Pool= $_.Pool
       Unpaid = $_.Unpaid
       Balance = $_.Balance
       Last_Checked = $_."Last Checked"
      }
    }
  }
  $Total_Unpaid = $($Pools.Unpaid | Measure-Object -Sum).Sum
  $Total_Balance = $($Pools.Balance | Measure-Object -Sum).Sum
  $Total_Estimated = [double]$Total_Unpaid + [Double]$Total_Balance
  $Last_Checked = $Pools.Last_Checked | Sort-Object | Select -First 1
  $Ticker = $SortTable.$Sel.Ticker | Select -First 1
  $Wallet_Table += [PSCustomObject]@{
   Wallet = $Sel
   Ticker = $Ticker
   Pool_Wallets = $Pools
   Total_Unpaid = $Total_Unpaid
   Total_Balance = $Total_Balance
   Total_Estimated = $Total_Estimated
   Last_Successful_Check = $Last_Checked
  }
}

$Formatted_Table = @()

$Wallet_Table | foreach{
$Formatted_Table += "Wallet = $($_.Wallet)"
$Formatted_Table += "Ticker = $($_.Ticker)"
$Formatted_Table += "Pools:"
$_.Pool_Wallets | foreach {
$Formatted_Table += "     Pool = $($_.Pool)"
$Formatted_Table += "         Unpaid = $($_.Unpaid -as [Decimal])"
$Formatted_Table += "         Balance = $($_.Balance -as [Decimal])"
$Formatted_Table += "         Last Checked = $($_.Last_Checked)"
}
$Formatted_Table += " "
$Formatted_Table += "Total Unpaid = $($_.Total_Unpaid -as [Decimal])"
$Formatted_Table += "Total Balance = $($_.Total_Balance -as [Decimal])"
$Formatted_Table += "Total Estimated = $($_.Total_Estimated -as [Decimal])"
$Formatted_Table += "Last Successful Check = $($_.Last_Successful_Check)"
$Formatted_Table += " "
$Formatted_Table += " "
$Formatted_Table += " "
}

$Formatted_Table
}