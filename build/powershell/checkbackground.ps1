function Start-Background {
    param(
      [Parameter(Mandatory=$false)]
      [String]$Dir,
      [Parameter(Mandatory=$false)]
      [String]$WorkingDir,
      [Parameter(Mandatory=$false)]
      [String]$Platforms,
      [Parameter(Mandatory=$false)]
      [String]$HiveId,
      [Parameter(Mandatory=$false)]
      [String]$HiveOS,
      [Parameter(Mandatory=$false)]
      [String]$HivePassword,
      [Parameter(Mandatory=$false)]
      [String]$HiveMirror,
      [Parameter(Mandatory=$false)]
      [String]$RejPercent,
      [Parameter(Mandatory=$false)]
      [String]$Remote,   
      [Parameter(Mandatory=$false)]
      [String]$API,
      [Parameter(Mandatory=$false)]
      [String]$APIPassword,
      [Parameter(Mandatory=$false)]
      [int]$Port

      )
  
      $BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
      $command = Start-Process "powershell" -WorkingDirectory $WorkingDir -ArgumentList "-executionpolicy bypass -windowstyle minimized -command `"&{`$host.ui.RawUI.WindowTitle = `'Background Agent`'; &.\Background.ps1 -WorkingDir `'$dir`' -Platforms `'$Platforms`' -HiveID `'$HiveID`' -HiveOS `'$HiveOS`' -HiveMirror $HiveMirror -HivePassword `'$HivePassword`' -Remote `'$Remote`' -Port `'$Port`' -APIPassword `'$APIPassword`' -API `'$API`' -RejPercent `'$RejPercent`'}`"" -WindowStyle Minimized -PassThru -Verb Runas
      $command.ID | Set-Content ".\build\pid\background_pid.txt"
      $BackgroundTimer.Restart()
      do
      {
      Start-Sleep -S 1
      Write-Host "Getting Process ID for Background Agent"
      $ProcessId = if(Test-Path ".\build\pid\background_pid.txt"){Get-Content ".\build\pid\background_pid.txt"}
      if($ProcessID -ne $null){$Process = Get-Process $ProcessId -ErrorAction SilentlyContinue}
      }until($ProcessId -ne $null -or ($BackgroundTimer.Elapsed.TotalSeconds) -ge 10)  
      $BackgroundTimer.Stop()
  }

function Start-BackgroundCheck {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Platforms
    )

  if($Platforms -eq "windows")
  {
  $oldbackground = ".\build\pid\background_pid.txt"
  if(Test-Path $oldbackground)
  {
  $bprocess = Get-Content $oldbackground
  if(Get-Process -id $bprocess -ErrorAction SilentlyContinue){Stop-Process -id $bprocess; remove-item $oldbackground}
  }
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