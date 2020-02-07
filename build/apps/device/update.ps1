$code = @()
$Code += "Class PCI_ID {"
$Code += "`t[Hashtable]`$Info= @{"
$A = Get-Content ".\build\apps\device\pci.ids" | Where { $_[0] -ne '#' -and $_ -ne "" }

$B = $A | Select -First 1
$name = $B.substring(4 + 2)
$vendor_id = $B.substring(0, 4)
$vendor = "`"$vendor_id   $name`""
$Code += "`t`t$vendor = @{"

$tab1 = $true
$tab2 = $false
$tab3 = $false

$A = $A | Select -Skip 1

## Do first line
$A | % {
    if ($_[0] -ne "`t") {
        $name = $_.substring(4 + 2)
        $vendor_id = $_.substring(0, 4)
        $vendor = "$vendor_id   $name".replace("`"","```"")
        $vendor = "`"$vendor`""
        $count = $code.count
        if ($tab1) {
            $code[$count - 1 ] += "}" 
        }
        elseif ($tab2) {
            $code[$code.count- 1 ] += "}"
            $code += "`t`t}"
        }
        elseif ($tab3) {
            $code += "`t`t`t}"
            $code += "`t`t}"
        }
        $tab1 = $true
        $tab2 = $false
        $tab3 = $false
        $Code += "`t`t$vendor = @{"
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
        $device = "$device_id   $name".replace("`"","```"")
        $device = "`"$device`""
        $count = $code.count
        if ($tab1) {
            $code += "`t`t`t$device = @{"
        }
        if ($tab2) {
            $code[$count - 1 ] += "}"
            $code += "`t`t`t$device = @{"
        }
        if ($tab3) {
            $code += "`t`t`t}"
            $code += "`t`t`t$device = @{"
        }
        $tab1 = $false
        $tab2 = $true
        $tab3 = $false
    }
    else {
        $split = $_.split("  ").Replace("`t", "")
        $subsys = $split[1].replace("`"","```"")
        $SubsysId = $split[0].replace("`"","```"")
        $code += "`t`t`t`t`"$SubsysId`" = `"$subsys`""
        $tab1 = $false
        $tab2 = $false
        $tab3 = $true
    }
}

$count = $code.count
$code[$count - 1] += "}"
$Code += "`t}"
$Code += "}"

$code | Set-Content ".\build\apps\device\pci_ids.ps1"