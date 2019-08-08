#settings (for autofan.conf without DEF_), default values
##DEF_TARGET_TEMP=
#minimal fan speed
##DEF_MIN_FAN=30
#maximum fan speed
##DEF_MAX_FAN=100
#temperature to stop miner
##DEF_CRITICAL_TEMP=90
#action on reaching critical temp. "" to stop mining, reboot, shutdown
##DEF_CRITICAL_TEMP_ACTION=
#AMD fan control (AMD control enable-0/AMD control disable-1)
##DEF_NO_AMD=0
#Reboot rig if GPU error (enable-1/disable-0)
##DEF_REBOOT_ON_ERROR=0

$global:Config = @{}
$global:Config.add("vars",@{})
$global:Config.vars.Add("dir",(Split-Path(Split-Path(Split-Path(Split-Path($script:MyInvocation.MyCommand.Path))))))
Set-Location $global:Config.vars.dir

Set-Alias -Name "jq" -Value ConvertFrom-Json
Set-Alias -Name "jc" -Value Convertto-Json

. .\build\powershell\global\modules.ps1

Create website @()

## Get Hive/SWARM configs:
if(test-path ".\build\txt\hiveconfig.txt") { 
    create "config" (cat ".\build\txt\hiveconfig.txt" | jq)
    $(vars).config.PSobject.Properties.Name | ForEach-Object { try{ $(vars).config.$_ = $(vars).config.$_ | ConvertFrom-StringData }catch{} }
    $(vars).config.PSobject.Properties.Name | ForEach-Object { try{ $Sel = $_; $(vars).config.$Sel = $(vars).config.$Sel.keys | % { @{ $_ = $(vars).config.$Sel.$_ -replace "`"","" } }}catch{} }
    $global:Websites += "HiveOS"
} elseif(test-path ".\build\txt\swarmconfig.txt") { 
    create "config" (cat ".\build\txt\hiveconfig.txt" | jq)
    $(vars).config.PSobject.Properties.Name | ForEach-Object { try{ $(vars).config.$_ = $(vars).config.$_ | ConvertFrom-StringData }catch{} }
    $(vars).config.PSobject.Properties.Name | ForEach-Object { try{ $Sel = $_; $(vars).config.$Sel = $(vars).config.$Sel.keys | % { @{ $_ = $(vars).config.$Sel.$_ -replace "`"","" } }}catch{} }
    $global:Websites += "SWARM"
} else{Write-Host "No configs found"}

$(vars).Add("startup", "$($(vars).dir)\build\powershell\startup")
$(vars).Add("web", "$($(vars).dir)\build\api\web")
$(vars).Add("global", "$($(vars).dir)\build\powershell\global")
$(vars).Add("build", "$($(vars).dir)\build\powershell\build")
$(vars).Add("pool", "$($(vars).dir)\build\powershell\pool")
$(vars).Add("miner", "$($(vars).dir)\build\powershell\miner")
$(vars).Add("control", "$($(vars).dir)\build\powershell\control")
$(vars).Add("run", "$($(vars).dir)\build\powershell\run")
$(vars).Add("benchmark", "$($(vars).dir)\build\powershell\benchmark")

$p = [Environment]::GetEnvironmentVariable("PSModulePath")
if ($P -notlike "*$($(vars).dir)\build\powershell*") {
    $P += ";$($(vars).startup)";
    $P += ";$($(vars).web)";
    $P += ";$($(vars).global)";
    $P += ";$($(vars).build)";
    $P += ";$($(vars).pool)";
    $P += ";$($(vars).miner)";
    $P += ";$($(vars).control)";
    $P += ";$($(vars).run)";
    $P += ";$($(vars).benchmark)";
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
    Write-Host "Modules Are Loaded" -ForegroundColor Green
}
Remove-Variable -name P -ErrorAction Ignore

create "miner_stopped_by_overheat" $false
create "unable_to_set_fan_speed" $false
create "temperature_is_unreal" $false
create "error_in_temp_readings" $false

Start-Transcript -Path "$(vars).dir\logs\autofan.log"

$DoNvidia = $false
$DoAMD = $False

if(Test-Path ".\build\txt\oclist.txt") { $Devices = Get-Content ".\build\txt\oclist.txt" | ConvertFrom-Json}
if($Devices.AMD.Count -gt 0){ $AMD_Cards = $Devices.AMD; $DoAMD = $True }
if($Devices.NVidia.Count -gt 0){ $NVIDIA_Cards = $Devices.NVIDIA; $DoNVIDIA = $True }




