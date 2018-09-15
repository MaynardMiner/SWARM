. .\Build\Hive\IncludeCoin.ps1

$AllStats = if(Test-Path "Stats")
{
    Get-ChildItemContent "Stats" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} 
}

$Allstats | ForEach-Object{
    if($_.Live -eq 0)
     {
      $Removed = Join-Path "Stats" "$($_.Name).txt"
      $Change = $($_.Name) -replace "HashRate","TIMEOUT"
      if(Test-Path (Join-Path "Backup" "$($Change).txt"))
       {
        Remove-Item (Join-Path "Backup" "$($Change).txt")
       }
      Remove-Item $Removed
      Write-Host "$($_.Name) Hashrate and Timeout Notification was Removed"
     }
}
