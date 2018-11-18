
 function Start-Webcommand {
  Param(
  [Parameter(Position=0, Mandatory=$false)]
    [Object]$Command
 )

  Write-Host "$($command.result.exec)"

 if($command.result.command -eq "OK")
  {
   Write-Host "Hive Received Stats"
  }

 if($command.result.command -eq "exec")
  {
   Switch -Wildcard ($command.result.exec)
    {
     "*stats*"
      {
       $type = "info"
       $data = "stats"
       $getpayload = Get-Content ".\build\bash\minerstats.sh"
       $line = @()
       $getpayload | foreach {$line += "$_`n"}
       $payload = $line
      }
      "*active*"
      {
       $type = "info"
       $data = "active"
       $getpayload = Get-Content ".\build\bash\mineractive.sh"
       $line = @()
       $getpayload | foreach {$line += "$_`n"}
       $payload = $line
      }
     "*query*"
      {
        $type = "info"
        $data = "$($command.result.exec)"
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\version.ps1 -platform windows -command query""" -Wait
        $getpayload = Get-Content ".\build\txt\version.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
      }
      "*update*"
      {
        $type = "info"
        $data = "$($command.result.exec)"
        $arguments = $data -replace ("version ","")
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\version.ps1 -platform windows -command $arguments"""
        Start-Sleep -S 12
        $getpayload = Get-Content ".\build\txt\version.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
      }
      "*reboot*"
      {
        $type = "info"
        $data = "$($command.result.exec)"
        $payload = "rebooting"
      }
      "*benchmark*"
      {
        $type = "info"
        $data = "$($command.result.exec)"
        $arguments = $data -replace ("benchmark ","")
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\benchmark.ps1 $arguments windows""" -Wait
        Start-Sleep -S 5
        $getpayload = Get-Content ".\build\txt\benchcom.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
      }
      "*get-screen*"
      {
        $type = "info"
        $data = "$($command.result.exec)"
        $arguments = $data -replace ("get-screen ","")
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\get-screen.ps1 -Type $arguments -platform windows""" -Wait
        Start-Sleep -S 5
        $getpayload = Get-Content ".\build\txt\logcom.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
      }
    }
  }

 if($command.result.command -eq "config")
  {
   $type = "ok"
   $data = "Rig config changed"
   $arguments = $command.result.wallet
   $start = $arguments.Lastindexof("CUSTOM_USER_CONFIG=") + 20
   $end = $arguments.LastIndexOf("META") - 3
   $arguments = $arguments.substring($start,($end-$start))
   $arguments = $arguments -replace "\'\\\'",""
   $arguments = $arguments -replace "\u0027","\'"
   $arguments = $arguments -split "-"
   $arguments = $arguments | foreach {$_.trim(" ")}
   $arguments = $arguments | Select -skip 1
   $argjson = @{}
   $arguments | foreach {$argument = $_ -split " " | Select -first 1; $argparam = $_ -split " " | Select -last 1; $argjson.Add($argument,$argparam);}
   $JsonParam = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
   $argjson = $argjson | ConvertTo-Json | ConvertFrom-Json
   $argjson | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name |  foreach{
    if($JsonParam.$_ -ne $argjson.$_)
     {
      $JsonParam.$_ = $argjson.$_
     }
     if(-not $JsonParam.$_)
     {
      $JsonParam.Add("$($_)",$argjson.$_)
     }
   }
   $JsonParam | convertto-Json | Out-File ".\config\parameters\arguments.json"
   $Datestamp = Get-Date
   "Params Have Changed: $DateStamp" | Set-Content ".\build\txt\paramchanged.txt"
  }

if($payload -ne $null)
{
$myresponse = @{
    method = "message"
    rig_id = $HiveID
    jsonrpc = "2.0"
    id= "0"
    params = @{
     id = $command.result.id
     rig_id = $HiveID
     passwd = $HivePassword
     type = $type
     data = $data
     payload = $payload
     }
    }
  }

else{
  $myresponse = @{
    method = "message"
    rig_id = $HiveID
    jsonrpc = "2.0"
    id= "0"
    params = @{
     id = $command.result.id
     rig_id = $HiveID
     passwd = $HivePassword
     type = $type
     data = $data
     }
    }
  }

   $myresponse     
  
}