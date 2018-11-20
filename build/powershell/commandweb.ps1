
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
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\version.ps1 -platform windows -command $arguments""" -Wait
        Start-Sleep -S 12
        $getpayload = Get-Content ".\build\txt\version.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line
      }
      "*get*"
      {
        $type = "info"
        $data = "$($command.result.exec)"
        $arguments = $data -replace ("get ","")
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\get.ps1 $arguments""" -Wait
        $getpayload = Get-Content ".\build\txt\get.txt"
        $line = @()
        $getpayload | foreach {$line += "$_`n"}
        $payload = $line 
      }
      "*benchmark *"
      {
        $type = "info"
        $data = "$($command.result.exec)"
        $arguments = $data -replace ("benchmark ","")
        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\benchmark.ps1 $arguments""" -Wait
        $getpayload = Get-Content ".\build\txt\get.txt"
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
    }
  }

 if($command.result.command -eq "config")
  {
   $type = "success"
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
       switch($_)
       {
        default{$JsonParam.$_ = $argjson.$_}
        "Type"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.$_ = $NewParamArray}
        "Poolname"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.$_ = $NewParamArray}
        "Currency"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.$_ = $NewParamArray}
        "PasswordCurrency1"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.$_ = $NewParamArray}
        "PasswordCurrency2"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.$_ = $NewParamArray}
        "PasswordCurrency3"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.$_ = $NewParamArray}
        "No_Algo"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.$_ = $NewParamArray}
       }
      }
     if(-not $JsonParam.$_)
      {
       switch($_)
       {
        default{$JsonParam.Add("$($_)",$argjson.$_)}
        "Type"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.Add("$($_)",$NewParamArray)}
        "Poolname"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.Add("$($_)",$NewParamArray)}
        "Currency"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.Add("$($_)",$NewParamArray)}
        "PasswordCurrency1"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.Add("$($_)",$NewParamArray)}
        "PasswordCurrency2"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.Add("$($_)",$NewParamArray)}
        "PasswordCurrency3"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.Add("$($_)",$NewParamArray)}
        "No_Algo"{$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $JsonParam.Add("$($_)",$NewParamArray)}
       }
      }
     }
   $JsonParam | convertto-Json | Out-File ".\config\parameters\newarguments.json"
   $Datestamp = Get-Date
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