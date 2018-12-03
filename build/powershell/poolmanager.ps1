function Remove-Pools {
    param (
    [Parameter(Mandatory=$true)]
    [String]$IPAddress,
    [Parameter(Mandatory=$true)]
    [Int]$PoolPort,
    [Parameter(Mandatory=$true)]
    [Int]$PoolTimeout
    )
    $getpool = "pools|0"
    $getpools = Get-TCP -Server $IPAddress -Port $Port -Message $getpool -Timeout $timeout
    if($getpools)
     {
    $ClearPools = @()
    $getpools = $getpools -split "\|" | Select -skip 1 | Where{$_ -ne ""}
    $AllPools = [PSCustomObject]@{}
    $Getpools | foreach {$Single = $($_ -split "," | ConvertFrom-StringData); $AllPools | Add-Member "Pool$($Single.Pool)" $Single}
    $AllPools | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach{if($AllPools.$_.Priority -ne 0){$Clear = $($_ -replace "Pool",""); $ClearPools += "removepool|$Clear"}else{$ThisPool = "$($_)"}}
    if($ClearPools){$ClearPools | foreach{Get-TCP -Server $Master -Port $Port -Message "$($_)" -Timeout $timeout};Start-Sleep -S .5}
     }
   
    if($ThisPool -eq "Pool1"){$Found = "0"}
    else{$Found = "1"}

    $Found
}