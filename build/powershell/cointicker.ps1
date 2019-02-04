function Get-PerSecond {
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [array]$GetPerSecond,
        [Parameter(Position = 0, Mandatory = $false)]
        [int]$Period
    )

    $GetPerSecond | Foreach {
        if ($_.Profit) {
            $Estimated = $($_.Profit)
            $Estimated = $Estimated / 86400
            $Estimated = $Estimated * $Inverval
        }
 
    }
}