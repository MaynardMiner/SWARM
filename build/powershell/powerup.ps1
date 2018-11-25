function Get-Power {
    param(
    [Parameter(Mandatory=$false)]
    [Array]$PwrType="none",
    [Parameter(Mandatory=$false)]
    [string]$Platforms="none"
    )

$Ncheck = $false
$Acheck = $false

$PwrType | foreach { 
  if($Platforms -eq "linux")
   {
    if($PwrType -like "*NVIDIA*" -and $Ncheck -eq $false)
    {
     $Ncheck = $true
     $CardPower = ".\build\txt\nvidiapower.txt"
     if(Test-Path $CardPower){Clear-Content $CardPower}
     timeout -s9 30 nvidia-smi --query-gpu=power.draw --format=csv | Tee-Object ".\build\txt\nvidiapower.txt" | Out-Null
    }

    elseif($PwrType -like "*AMD*" -and $Acheck -eq $false)
     {
      $Acheck = $true
      $CardPower = ".\build\txt\amdpower.txt"
      if(Test-Path $CardPower){Clear-Content $CardPower}
      Start-Process ".\build\bash\rocm.sh" -Wait
     }
    }
  }
}

function Set-Power {
    param(
    [Parameter(Mandatory=$false)]
    [String]$MinerDevices,
    [Parameter(Mandatory=$false)]
    [String]$Command,
    [Parameter(Mandatory=$false)]
    [String]$PwrType
    ) 

 if($Platform -eq "linux")
 {
 if(Test-Path ".\build\txt\nvidiapower.txt"){$NPow = get-content ".\build\txt\nvidiapower.txt" | ConvertFrom-Csv}
 if(Test-Path ".\build\txt\amdpower.txt"){$APow = Get-Content ".\build\txt\amdpower.txt" | Select-String -CaseSensitive "W" | foreach {$_ -split (":","") | Select -skip 2 -first 1} | foreach {$_ -replace ("W","")}}
 }

 $PwrDevices = get-content ".\build\txt\devicelist.txt" | ConvertFrom-Json
 $PwrMiners = get-content ".\build\txt\bestminers.txt" | ConvertFrom-Json

 if($Platform -eq "windows")
 {
  $POWN = $false
  $POWA = $false
  $PwrMiners | foreach{if($_.Type -like "*NVIDIA*"){$POWN=$true};if($_.Type -like "*AMD*"){$POWA=$true}}
  if($POWN -eq $true)
  {
  if($nvidiaout){Clear-Variable nvidiaout}
  invoke-expression ".\build\apps\nvidia-smi.exe --query-gpu=power.draw --format=csv" | Tee-Object -Variable nvidiaout | OUt-Null
  $NPow = $nvidiaout | ConvertFrom-Csv
  }
  if($POWA -eq $true)
  {
    if($amdout){Clear-Variable amdout}
    Invoke-Expression ".\build\apps\overdriveVII.exe -y" | Tee-Object -Variable amdout | OUt-Null
    $amdinfo = $amdout | ConvertFrom-StringData
    $APow = @()
    $amdinfo.keys | foreach {if($_ -like "*Watts*"){$APow += $amdinfo.$_}}
  }
 }

if($PwrType -like "*NVIDIA*")
 {
  $GPUPower = [PSCustomObject]@{}
  $TypeS = "NVIDIA"
  if($MinerDevices){$Devices = Get-DeviceString -TypeDevices "$($MinerDevices)"}
  else{$Devices = Get-DeviceString -TypeCount $($PwrDevices.$TypeS.PSObject.Properties.Value.Count)}
  for($i=0; $i -lt $PwrDevices.NVIDIA.PSObject.Properties.Value.Count; $i++){$GPUPower | Add-Member -MemberType NoteProperty -Name "$($PwrDevices.NVIDIA.$i)" -Value 0}
  $PowerArray = @()
  $Power = $NPow."power.draw [W]" | foreach { $_ -replace ("W","")}
  $Power = $Power | foreach {$_ -replace ("\[Not Supported\]","75")}  
  for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUPower.$($PwrDevices.$TypeS.$GPU) = $(if($Power.Count -eq 1){$Power}else{$Power[$GPU]})}
  if($GPUPower -ne $null){$GPUPower | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$PowerArray += [Double]$($GPUPower.$_)}}
  $TotalPower = 0
  $PowerArray | foreach {$TotalPower += $_}
  if($Command -eq "hive"){$PowerArray}
  elseif($Command -eq "stat"){$TotalPower}
 }

if($PwrType -like "*AMD*")
 {
  $GPUPower = [PSCustomObject]@{}
  $TypeS = "AMD"
  if($MinerDevices){$Devices = Get-DeviceString -TypeDevices $MinerDevices}
  else{$Devices = Get-DeviceString -TypeCount $($PwrDevices.$TypeS.PSObject.Properties.Value.Count)}
  for($i=0; $i -lt $PwrDevices.AMD.PSObject.Properties.Value.Count; $i++){$GPUPower | Add-Member -MemberType NoteProperty -Name "$($PwrDevices.AMD.$i)" -Value 0}
  $PowerArray = @()
  if($Platform -eq "linux"){$Power = $APow | foreach {$_ -split $_[1] | Select -last 1}}
  else{$Power = $APow}
  for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUPower.$($PwrDevices.$TypeS.$GPU) = $(if($Power.Count -eq 1){$Power}else{$Power[$GPU]})}
  if($GPUPower -ne $null){$GPUPower | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$PowerArray += [Double]$($GPUPower.$_)}}
  $TotalPower = 0
  $PowerArray | foreach {$TotalPower += $_}
  if($Command -eq "hive"){$PowerArray}
  elseif($Command -eq "stat"){$TotalPower}
 }
}