function Get-DeviceString {
    param(
        [Parameter(Mandatory = $false)]
        [String]$TypeDevices = "none",
        [Parameter(Mandatory = $false)]
        [String]$TypeCount
    )

    if ($TypeDevices -ne "none") {
        $TypeDevices = $TypeDevices -replace (",", " ")
        if ($TypeDevices -match " ") {$NewDevices = $TypeDevices -split " "}else {$NewDevices = $TypeDevices -split ""}
        $NewDevices = Switch ($NewDevices) {"a" {"10"}; "b" {"11"}; "c" {"12"}; "e" {"13"}; "f" {"14"}; "g" {"15"}; "h" {"16"}; "i" {"17"}; "j" {"18"}; "k" {"19"}; "l" {"20"}; default {"$_"}; }
        if ($TypeDevices -match " ") {$TypeGPU = $NewDevices}else {$TypeGPU = $NewDevices | ? {$_.trim() -ne ""}}
        $TypeGPU = $TypeGPU | % {iex $_}
    }
    else {
        $TypeGPU = @()
        $GetDevices = 0
        for ($i = 0; $i -lt $TypeCount; $i++) {$TypeGPU += $GetDevices++}
    }

    $TypeGPU
}

