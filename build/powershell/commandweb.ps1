
 function Start-Webcommand {
  Param(
  [Parameter(Position=0, Mandatory=$false)]
    [Object]$Command
 )

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
        $arguments = $data -replace ("benchmark ","")
        $data = "$($command.result.exec)"
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\benchmark.ps1 -name $arguments -platform windows""" -Wait
        Start-Sleep -S 5
        $getpayload = Get-Content ".\build\txt\benchcom.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
      }
      "*get-screen*"
      {
        $type = "info"
        $arguments = $data -replace ("get-screen ","")
        $data = "$($command.result.exec)"
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\get-screen.ps1 -Type $arguments -platform windows""" -Wait
        Start-Sleep -S 5
        $getpayload = Get-Content ".\build\txt\logcom.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
      }
    }
  }

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

   $myresponse     
  
}