$pci_ids = Get-Content ".\apps\device\pci.ids" | Where { $_[0] -ne '#' -and $_ -ne "" }

$device_list = @{ }

$pci_ids | % {
    if ($_[0] -ne "`t") {
        $name = $_.substring(4 + 2)
        $vendor_id = $_.substring(0, 4)
        $vendor = "$vendor_id   $name"
        $device_list.Add($vendor, @{ })
    }
    elseif ($_[0] -eq "`t" -and $_[1] -ne "`t") {
        $flag = $false
        $device_id = $_.Substring(1, 4)
        if ($device_id -like "* *") {
            $Device_id = $device_Id.Substring(0, 2)
            $flag = $true
        }
        if ($flag -eq $true) {
            $name = $_.substring(3 + 2)
        }
        else {
            $name = $_.substring(5 + 2)
        }
        $device = "$device_id   $name"
        $device_list.$vendor.Add($device, @{ })
    }
    else {
        $split = $_.split("  ").Replace("`t", "")
        $subsys = $split[1]
        $subsys_id = $split[0]
        $device_list.$vendor.$device.Add($subsys_id, $subsys)
    }
}

$device_list | ConvertTo-Json -Depth 10 | Set-Content ".\apps\device\pci_ids.json"
