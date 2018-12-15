function Set-Stat {
    param(
        [Parameter(Mandatory=$true)]
        [String]$Pool,
        [Parameter(Mandatory=$true)]
        [String]$Algo,
        [Parameter(Mandatory=$true)]
        [Double]$HashRate,         
        [Parameter(Mandatory=$true)]
        [Double]$Estimate, 
        [Parameter(Mandatory=$false)]
        [DateTime]$Date = (Get-Date)
    )

    $Path = "new-stats\$algo.json"
    $Date = $Date.ToUniversalTime()
    $SmallestValue = 1E-20

    if(Test-Path $Path){$Stat = Get-Content $Path | ConvertFrom-Json}

    if(-not $Stat.$Pool)
    {
      $PoolStat = [PSCustomObject]@{
       
      }
    }