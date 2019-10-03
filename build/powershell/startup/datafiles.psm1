<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

function Global:Get-DateFiles {
    param (
        [Parameter(Mandatory = $false)]
        [String]$CmdDir
    )
    
    if (Test-Path ".\build\pid") {Remove-Item ".\build\pid\*" -Force | Out-Null}
    else {New-Item -Path ".\build" -Name "pid" -ItemType "Directory" | Out-Null}
    Start-Sleep -S 1
    $PID | Out-File ".\build\pid\miner_pid.txt"
    if ($(arg).Platform -eq "windows") { $host.ui.RawUI.WindowTitle = "SWARM"; }
}

function Global:get-argnotice {
    if ((Test-Path ".\config\parameters\newarguments.json") -or $Debug -eq $true) {
        log "Detected New Arguments- Changing Parameters" -ForegroundColor Cyan
        log "These arguments can be found/modified in config < parameters < newarguments.json" -ForegroundColor Cyan
        Start-Sleep -S 2
    }    
}

function Global:Clear-Stats {
    $FileClear = @()
    $FileClear += ".\build\txt\minerstats.txt"
    $FileClear += ".\build\txt\mineractive.txt"
    $FileClear += ".\build\bash\hivecpu.sh"
    $FileClear += ".\build\txt\profittable.txt"
    $FileClear += ".\build\txt\bestminers.txt"
    $FileClear | ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Force } }
}

function Global:Set-NewType {
    $(arg).Type | ForEach-Object {
        if ($_ -eq "amd1") { $_ = "AMD1" }
        if ($_ -eq "nvidia1") { $_ = "NVIDIA1" }
        if ($_ -eq "nvidia2") { $_ = "NVIDIA2" }
        if ($_ -eq "nvidia2") { $_ = "NVIDIA3" }
        if ($_ -eq "cpu") { $_ = "CPU" }
        if ($_ -eq "asic") { $_ = "ASIC" }
    }    
}

function Global:get-NIST {
    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    try {$WebRequest = Invoke-WebRequest -Uri 'http://nist.time.gov/actualtime.cgi' -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} catch{Write-Warning "NIST Server Timed Out. Using Local Time"; return Get-Date }
    $milliseconds = [int64](($webRequest.Content -replace '.*timestamp time="|" delay=".*') / 1000)
    $NistTime = (New-Object -TypeName DateTime -ArgumentList (1970, 1, 1)).AddMilliseconds($milliseconds)
    $GetNIST = [System.TimeZoneInfo]::ConvertTimeFromUtc($NistTime, (Get-Timezone))
    return $GetNIST
}

function Global:Add-New_Variables {
$(vars).Add("No_Miner",0)
$(vars).Add("Instance",1)
$(vars).Add("ActiveMinerPrograms",@())
$(vars).Add("options",0)
$(vars).Add("DWallet",$null)
$(vars).Add("DCheck",$false)
$(vars).Add("Warnings",@())
$(vars).Add("Watts",$Null)
if ($(arg).Timeout) { $(vars).ADD("TimeoutTime",[Double]$(arg).Timeout * 3600) }
else { $(vars).Add("TimeoutTime",10000000000) }
$(vars).Add("TimeoutTimer",(New-Object -TypeName System.Diagnostics.Stopwatch))
$(vars).TimeoutTimer.Start()
$(vars).Add("logtimer",(New-Object -TypeName System.Diagnostics.Stopwatch))
$(vars).logtimer.Start()
$(vars).Add("QuickTimer",(New-Object -TypeName System.Diagnostics.Stopwatch))
$(vars).Add("MinerWatch",(New-Object -TypeName System.Diagnostics.Stopwatch))
$(vars).Add("WattEx",$Null)
$(vars).Add("Rates",$Null)
$(vars).Add("BestActiveMiners",@())
$(vars).Add("BTCExchangeRate",$Null)
$(vars).Add("BanCount",0)
$(vars).Add("BanPass",0)
$(vars).Add("Priority",@{Admin = $false; Other = $false})
$(vars).Add("AdminTime",0)
if(test-Path ".\build\data\deviation.txt"){$(vars).Add("Deviation",[Double](Get-Content ".\build\data\deviation.txt"))} 
else{$(vars).Add("Deviation",0)}
$(vars).Add("BenchmarkMode",$true)
$(vars).Add("bestminers_combo",$Null)
$(vars).Add("Active_Variables",(New-Object System.Collections.ArrayList))
$(vars).Add("NetModules",@())
$(vars).Add("WebSites",@())
$(vars).Add("ActiveSymbol",@())
$GetBanCheck2 = Get-Content ".\build\data\verification.conf" -Force
$BanCheck2 = $([Double]$GetBanCheck2[0] - 5 + ([Double]$GetBanCheck2[1] * 2))
$(vars).BanPass = "$($BanCheck2)"
}