function Start-BackgroundCheck {
    param(
        [Parameter(Mandatory=$false)]
        [object]$BestMiners,
        [Parameter(Mandatory=$false)]
        [object]$Platforms
    )

$Restart = $false

$BestMiners | foreach {
 if($_.XProcess.HasExited -eq $false -or $_.XProcess -eq $null){$Restart = $true}
}

if($Restart -eq $true)
 {
  if($Platforms -eq "windows")
  {
  $oldbackground = ".\build\pid\background_pid.txt"
  if(Test-Path $oldbackground)
  {
  $bprocess = Get-Content $oldbackground
  if(Get-Process -id $bprocess -ErrorAction SilentlyContinue){Stop-Process -id $bprocess; remove-item $oldbackground}
  }
  Start-Background -WorkingDir $pwsh -Dir $dir -Platforms $Platform -HiveID $HiveID -HiveMirror $HiveMirror -HivePassword $HivePassword -RejPercent $Rejections
  }
 elseif($Platforms -eq "linux")
  {
   Start-Process ".\build\bash\killall.sh" -ArgumentList "background" -Wait
   Start-Sleep -S .25
   Start-Process "screen" -ArgumentList "-S background -d -m" -Wait
   Start-Sleep -S .25
   Start-Process ".\build\bash\background.sh" -ArgumentList "background $dir $Platform $HiveOS $Rejections" -Wait
  }
 } 
}