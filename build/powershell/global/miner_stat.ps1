function Global:Get-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    $name = $name -replace "`/", "`-"
    if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" }
    if ($name -eq "load-average") { Get-ChildItem "debug" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json }
    else { Get-ChildItem "stats" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json }
}
