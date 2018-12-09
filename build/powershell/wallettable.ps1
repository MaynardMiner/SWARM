function Get-WalletTable {

    . .\build\powershell\childitems.ps1
    . .\build\powershell\statcommand.ps1

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

$WalletTable
}