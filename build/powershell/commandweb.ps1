
 function Start-Webcommand {
  Param(
  [Parameter(Position=0, Mandatory=$false)]
  [Object]$Command
 )

 . .\build\powershell\response.ps1

  Switch($Command.result.command )
  { 
  
  "OK"{$trigger = "stats"}

  "reboot"
  {
   $method = "message"
   $messagetype = "success"
   $data = "Rebooting"
   $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
   $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
   $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
   Write-Host $method $messagetype $data
   $trigger = "reboot"
   Restart-Computer
  }

  ##upgrade

  "exec"
   {
    Switch -Wildcard ($command.result.exec)
    {
     "*stats*"
      {
       $method = "message"
       $messagetype = "info"
       $data = "stats"
       $getpayload = Get-Content ".\build\bash\minerstats.sh"
       $line = @()
       $getpayload | foreach {$line += "$_`n"}
       $payload = $line
       $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
       $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
       $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
       Write-Host $method $messagetype $data
       $trigger = "exec"
      }
      "*active*"
      {
       $method = "message"
       $messagetype = "info"
       $data = "active"
       $getpayload = Get-Content ".\build\bash\mineractive.sh"
       $line = @()
       $getpayload | foreach {$line += "$_`n"}
       $payload = $line
       $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
       $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
       $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
       Write-Host $method $messagetype $data
       $trigger = "exec"
      }
     "*version query*"
      {
        $method = "message"
        $messagetype = "info"
        $data = "$($command.result.exec)"
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\version.ps1 -platform windows -command query""" -Wait
        $getpayload = Get-Content ".\build\txt\version.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
        $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
        $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
        Write-Host $method $messagetype $data
        $trigger = "exec"
      }
      "*version update*"
      {
        $method = "message"
        $messagetype = "info"
        $data = "$($command.result.exec)"
        $arguments = $data -replace ("version ","")
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\version.ps1 -platform windows -command $arguments""" -Wait
        Start-Sleep -S 12
        $getpayload = Get-Content ".\build\txt\version.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
        $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
        $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
        Write-Host $method $messagetype $data
        $trigger = "exec"
      }
      "*get*"
      {
        $method = "message"
        $messagetype = "info"
        $data = "$($command.result.exec)"
        $arguments = $data -replace ("get ","")
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\get.ps1 $arguments""" -Wait
        $getpayload = Get-Content ".\build\txt\get.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
        $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
        $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
        Write-Host $method $messagetype $data
        $trigger = "exec"
      }
      "*benchmark*"
      {
        $method = "message"
        $messagetype = "info"
        $data = "$($command.result.exec)"
        $arguments = $data -replace ("benchmark ","")
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\benchmark.ps1 $arguments""" -Wait
        $getpayload = Get-Content ".\build\txt\get.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line 
        $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
        $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
        Write-Host $method $messagetype $data
        $trigger = "exec"
      }
     }
    }

 "config"
  {

    $Command.result | ConvertTo-Json | Set-Content ".\build\txt\hiveconfig.txt"

    if($command.result.config)
    {
    $config = [string]$command.result.config | ConvertFrom-StringData
    $worker = $config.WORKER_NAME -replace "`"",""
    $Pass = $config.RIG_PASSWD -replace "`"",""
    $mirror = $config.HIVE_HOST_URL -replace "`"",""
    $WorkerID = $config.RIG_ID
    $NewHiveKeys = @{}
    $NewHiveKeys.Add("HiveWorker","$worker")
    $NewHiveKeys.Add("HivePassword","$Pass")
    $NewHiveKeys.Add("HiveID","$WorkerID")
    $NewHiveKeys.Add("HiveMirror","$mirror")
    if(Test-Path ".\build\txt\hivekeys.txt"){$OldHiveKeys = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json}
    if($OldHiveKeys)
     {
      if($NewHiveKeys.HivePassword -ne $OldHiveKeys.HivePassword)
       {
        Write-Warning "Detected New Password"
        $method = "message"
        $messagetype = "warning"
        $data = "Password change received, wait for next message..."
        $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
        $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
        $SendResponse
        $DoResponse = @{method = "password_change_received"; params = @{rig_id = $HiveID; passwd = $HivePassword}; jsonrpc = "2.0"; id= "0"}
        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
        $Send2Response = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
       }
     }
    $NewHiveKeys | ConvertTo-Json | Set-Content ".\build\txt\hivekeys.txt"        
    }
    ##DO OC HERE##

    if($Command.result.wallet)
    {
    $method = "message"
    $messagetype = "success"
    $data = "Rig config changed"
    $arguments = $command.result.wallet
    $argjson = @{}
    $start = $arguments.Lastindexof("CUSTOM_USER_CONFIG=") + 20
    $end = $arguments.LastIndexOf("META") - 3
    $arguments = $arguments.substring($start,($end-$start))
    $arguments = $arguments -replace "\'\\\'",""
    $arguments = $arguments -replace "\u0027","\'"
    $arguments = $arguments -split "-"
    $arguments = $arguments | foreach {$_.trim(" ")}
    $arguments = $arguments | Select -skip 1
    $arguments | foreach {$argument = $_ -split " " | Select -first 1; $argparam = $_ -split " " | Select -last 1; $argjson.Add($argument,$argparam);}
    $argjson = $argjson | ConvertTo-Json | ConvertFrom-Json

    $Defaults= Get-Content ".\config\parameters\default.json" | ConvertFrom-Json   
    $Params = @{}

    $Defaults |Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | %{$Params.Add("$($_)","$($Defaults.$_)")}

    $argjson | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name |  foreach{
    if($Params.$_ -ne $argjson.$_)
     {
       switch($_)
       {
        default{$Params.$_ = $argjson.$_}
        "Type"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
        "Poolname"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
        "Currency"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
        "PasswordCurrency1"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
        "PasswordCurrency2"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
        "PasswordCurrency3"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
        "No_Algo"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
       }
      }
     }

   $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
   $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
   $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
   $SendResponse
   $Params | convertto-Json | Out-File ".\config\parameters\newarguments.json"
    }
   $trigger = "config"

   }
  }
  $trigger

 }