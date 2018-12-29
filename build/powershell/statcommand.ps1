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

function get-NIST {
    $progressPreference = 'silentlyContinue'
    try
     {
      $WebRequest = Invoke-WebRequest -Uri 'http://nist.time.gov/actualtime.cgi' -UseBasicParsing -TimeoutSec 5
      $GetNIST = (Get-Date -Date '1970-01-01 00:00:00Z').AddMilliseconds(([XML]$WebRequest.Content | Select -expandproperty timestamp | Select -ExpandProperty time) / 1000)
     }
    Catch
     {
     Write-Warning "Failed To Get NIST time. Using Local Time."
     $GetNIST = Get-Date
     }
    $progressPreference = 'Continue'
   $GetNIST
}

function get-stats {
param(
[Parameter(Mandatory=$true)]
[String]$Timeouts
)

if($Timeouts -eq "No")
{ 
 $GetStats = [PSCustomObject]@{}
 if(Test-Path "stats"){Get-ChildItemContent "stats" | ForEach {$GetStats | Add-Member $_.Name $_.Content}}
 $GetStats
}

if($Timeouts -eq "Yes")
 {
  $GetStats = [PSCustomObject]@{}
  if(Test-Path ".\timeout"){Remove-Item ".\timeout" -Force -Recurse}
  Write-Host "Cleared all bans" -ForegroundColor Green
  Start-Sleep -S 3
  if(Test-Path "stats"){Get-ChildItemContent "stats" | ForEach {$GetStats | Add-Member $_.Name $_.Content}}
  $GetStats
 }

}

function Set-Stat {
  param(
      [Parameter(Mandatory=$true)]
      [String]$Name, 
      [Parameter(Mandatory=$true)]
      [Double]$Value, 
      [Parameter(Mandatory=$false)]
      [DateTime]$Date = (Get-Date)
  )

  if($name -eq "load-average"){$Path = "build\txt\$Name.txt"}
  else{$Path = "stats\$Name.txt"}
  $Date = $Date.ToUniversalTime()
  $SmallestValue = 1E-20

  $Stat = [PSCustomObject]@{
      Live = $Value
      Minute = $Value
      Minute_Fluctuation = 1/2
      Minute_5 = $Value
      Minute_5_Fluctuation = 1/2
      Minute_10 = $Value
      Minute_10_Fluctuation = 1/2
      Hour = $Value
      Hour_Fluctuation = 1/2
      Day = $Value
      Day_Fluctuation = 1/2
      Week = $Value
      Week_Fluctuation = 1/2
      Updated = $Date
  }

  if(Test-Path $Path){$Stat = Get-Content $Path | ConvertFrom-Json}

  $Stat = [PSCustomObject]@{
      Live = [Double]$Stat.Live
      Minute = [Double]$Stat.Minute
      Minute_Fluctuation = [Double]$Stat.Minute_Fluctuation
      Minute_5 = [Double]$Stat.Minute_5
      Minute_5_Fluctuation = [Double]$Stat.Minute_5_Fluctuation
      Minute_10 = [Double]$Stat.Minute_10
      Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
      Hour = [Double]$Stat.Hour
      Hour_Fluctuation = [Double]$Stat.Hour_Fluctuation
      Day = [Double]$Stat.Day
      Day_Fluctuation = [Double]$Stat.Day_Fluctuation
      Week = [Double]$Stat.Week
      Week_Fluctuation = [Double]$Stat.Week_Fluctuation
      Updated = [DateTime]$Stat.Updated
  }
  
  $Span_Minute = [Math]::Min(($Date-$Stat.Updated).TotalMinutes,1)
  $Span_Minute_5 = [Math]::Min((($Date-$Stat.Updated).TotalMinutes/5),1)
  $Span_Minute_10 = [Math]::Min((($Date-$Stat.Updated).TotalMinutes/10),1)
  $Span_Hour = [Math]::Min(($Date-$Stat.Updated).TotalHours,1)
  $Span_Day = [Math]::Min(($Date-$Stat.Updated).TotalDays,1)
  $Span_Week = [Math]::Min((($Date-$Stat.Updated).TotalDays/7),1)

  $Stat = [PSCustomObject]@{
      Live = $Value
      Minute = ((1-$Span_Minute)*$Stat.Minute)+($Span_Minute*$Value)
      Minute_Fluctuation = ((1-$Span_Minute)*$Stat.Minute_Fluctuation)+
          ($Span_Minute*([Math]::Abs($Value-$Stat.Minute)/[Math]::Max([Math]::Abs($Stat.Minute),$SmallestValue)))
      Minute_5 = ((1-$Span_Minute_5)*$Stat.Minute_5)+($Span_Minute_5*$Value)
      Minute_5_Fluctuation = ((1-$Span_Minute_5)*$Stat.Minute_5_Fluctuation)+
          ($Span_Minute_5*([Math]::Abs($Value-$Stat.Minute_5)/[Math]::Max([Math]::Abs($Stat.Minute_5),$SmallestValue)))
      Minute_10 = ((1-$Span_Minute_10)*$Stat.Minute_10)+($Span_Minute_10*$Value)
      Minute_10_Fluctuation = ((1-$Span_Minute_10)*$Stat.Minute_10_Fluctuation)+
          ($Span_Minute_10*([Math]::Abs($Value-$Stat.Minute_10)/[Math]::Max([Math]::Abs($Stat.Minute_10),$SmallestValue)))
      Hour = ((1-$Span_Hour)*$Stat.Hour)+($Span_Hour*$Value)
      Hour_Fluctuation = ((1-$Span_Hour)*$Stat.Hour_Fluctuation)+
          ($Span_Hour*([Math]::Abs($Value-$Stat.Hour)/[Math]::Max([Math]::Abs($Stat.Hour),$SmallestValue)))
      Day = ((1-$Span_Day)*$Stat.Day)+($Span_Day*$Value)
      Day_Fluctuation = ((1-$Span_Day)*$Stat.Day_Fluctuation)+
          ($Span_Day*([Math]::Abs($Value-$Stat.Day)/[Math]::Max([Math]::Abs($Stat.Day),$SmallestValue)))
      Week = ((1-$Span_Week)*$Stat.Week)+($Span_Week*$Value)
      Week_Fluctuation = ((1-$Span_Week)*$Stat.Week_Fluctuation)+
          ($Span_Week*([Math]::Abs($Value-$Stat.Week)/[Math]::Max([Math]::Abs($Stat.Week),$SmallestValue)))
      Updated = $Date
  }

  if(-not (Test-Path "stats")){New-Item "stats" -ItemType "directory"}
  [PSCustomObject]@{
      Live = [Decimal]$Stat.Live
      Minute = [Decimal]$Stat.Minute
      Minute_Fluctuation = [Double]$Stat.Minute_Fluctuation
      Minute_5 = [Decimal]$Stat.Minute_5
      Minute_5_Fluctuation = [Double]$Stat.Minute_5_Fluctuation
      Minute_10 = [Decimal]$Stat.Minute_10
      Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
      Hour = [Decimal]$Stat.Hour
      Hour_Fluctuation = [Double]$Stat.Hour_Fluctuation
      Day = [Decimal]$Stat.Day
      Day_Fluctuation = [Double]$Stat.Day_Fluctuation
      Week = [Decimal]$Stat.Week
      Week_Fluctuation = [Double]$Stat.Week_Fluctuation
      Updated = [DateTime]$Stat.Updated
  } | ConvertTo-Json | Set-Content $Path 

  $Stat
}

function Get-Stat {
  param(
      [Parameter(Mandatory=$true)]
      [String]$Name
  )

  if(-not (Test-Path "stats")){New-Item "stats" -ItemType "directory"}
  if($name -eq "load-average"){Get-ChildItem "build\txt" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json}
  else{Get-ChildItem "stats" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json}
}

function Remove-Stat {
  param(
        [Parameter(Mandatory=$true)]
  [String]$Name
 )

   $Remove = Join-Path ".\stats" "$Name"
   if(Test-Path $Remove)
    {
Remove-Item -path $Remove
    }
}

function Set-WStat {
    param(
        [Parameter(Mandatory=$true)]
        [String]$Name,
        [Parameter(Mandatory=$true)]
        [String]$Symbol,
        [Parameter(Mandatory=$true)]
        [String]$address,
        [Parameter(Mandatory=$true)]
        [Double]$balance,
        [Parameter(Mandatory=$true)]
        [Double]$unpaid,
        [Parameter(Mandatory=$false)]
        [DateTime]$Date = (Get-Date)
    )

$Path = ".\wallet\values\$Name.txt"
$Date = $Date.ToUniversalTime()
$Pool = $Name -split "_" | Select -First 1

if(Test-Path $Path){$WStat = Get-Content $Path | ConvertFrom-Json}
if($WStat)
{
   $WStat.address = $address;
   $WStat.symbol = $symbol;
   $WStat.Pool = $Pool;
   $WStat.balance = $balance;
   $WStat.unpaid = $unpaid;
   $WStat.Date = $Date
}
else{
    $WStat = [PSCustomObject]@{
    Address = $address;
    Symbol = $symbol;
    Pool = $Pool;
    Balance = $balance; 
    Unpaid = $unpaid; 
    Date=$Date
    }
 }
if(-not (Test-Path ".\wallet\values")){New-Item -Name "values" -Path ".\wallet" -ItemType "directory" | Out-Null}

$WStat | ConvertTo-Json | Set-Content $Path 

}

function get-wstats {
         $GetWStats = [PSCustomObject]@{}
         if(Test-Path ".\wallet\values"){Get-ChildItemContent ".\wallet\values" | ForEach {$GetWStats | Add-Member $_.Name $_.Content}}
         $GetWStats
}

function Invoke-SwarmMode {

    param (
    [Parameter(Position=0, Mandatory=$false)]
    [datetime]$SwarmMode_Start,
    [Parameter(Position=1, Mandatory=$false)]
    [int]$ModeDeviation = 5
    )




    $DateMinute = [Int]$SwarmMode_Start.Minute + $ModeDeviation
    $DateMinute = ([math]::Floor(($DateMinute/$ModeDeviation))*$ModeDeviation)
    if($DateMinute -gt 59){$DateMinute = 0; $DateHour = [Int]$SwarmMode_Start.Hour; $DateHour = [int]$DateHour + 1}else{$DateHour = [Int]$SwarmMode_Start.Hour; $DateHour = [int]$DateHour}
    if($DateHour -gt 23){$DateHour = 0; $DateDay = [Int]$SwarmMode_Start.Day;  $DateDay = [int]$DateDay + 1}else{$DateDay = [Int]$SwarmMode_Start.Day; $DateDay = [int]$DateDay}
    if($DateDay -gt 31){$DateDay = 1; $DateMonth = [Int]$SwarmMode_Start.Month; $DateMonth = [int]$DateMonth + 1}else{$DateMonth = [Int]$SwarmMode_Start.Month; $DateMonth = [int]$DateMonth}
    if($DateMonth -gt 12){$DateMonth = 1; $DateYear = [Int]$SwarmMode_Start.Year; $DateYear = [int]$DateYear + 1}else{$DateYear = [Int]$SwarmMode_Start.Year; $DateYear = [int]$DateYear}
    $ReadyValue = (Get-Date -Year $DateYear -Month $DateMonth -Day $DateDay -Hour $DateHour -Minute $DateMinute -Second 0 -Millisecond 0)
    $StartValue = [math]::Round((([DateTime](get-date))-$ReadyValue).TotalSeconds)
    $StartValue
}