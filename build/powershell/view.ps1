Param (
  [Parameter(Mandatory = $true)]
  [int]$n,
  [Parameter(Mandatory = $false, Position=0)]
  [string]$Command,
  [Parameter(Mandatory = $false, Position=1)]
  [string]$Arg1,
  [Parameter(Mandatory = $false, Position=2)]
  [string]$Arg2,
  [Parameter(Mandatory = $false, Position=3)]
  [string]$Arg3,
  [Parameter(Mandatory = $false, Position=4)]
  [string]$Arg4,
  [Parameter(Mandatory = $false, Position=5)]
  [string]$Arg5,
  [Parameter(Mandatory = $false, Position=6)]
  [string]$Arg6,
  [Parameter(Mandatory = $false, Position=7)]
  [string]$Arg7,
  [Parameter(Mandatory = $false, Position=8)]
  [string]$Arg8,
  [Parameter(Mandatory = $false, Position=9)]
  [string]$Arg9,
  [Parameter(Mandatory = $false, Position=10)]
  [string]$Arg10,
  [Parameter(Mandatory = $false)]
  [switch]$OnChange
)

if(-not $n){$n = 5}

While($True) {
  $OutPut = $null
  Invoke-Expression "$Command $Arg1 $Arg2 $Arg3 $Arg4 $Arg5 $Arg6 $Arg7 $Arg8 $Arg9 $Arg10" | Tee-Object -Variable Output | Out-Null;
  if($OnChange.IsPresent) {
    if([string]$Previous -ne [string]$OutPut) {
      Clear-Host   
      Write-Host "Refreshing Screen Every $N seconds"  
      $Output; 
      $Previous = $OutPut
    }
  }
  else {
    Clear-Host   
    Write-Host "Refreshing Screen Every $N seconds"
    $OutPut
  }
  Start-Sleep -S $n
}