$Commands = [PSCustomObject]@{

    "Equihash" = [PSCustomObject]@{
    "bitmain-use-vil" = "true"
    "bitmain-freq" = "575"
    "bitmain-fan-ctrl" = "true"
    "bitmain-fan-pwm" = "56"
    }

}

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
$Arguments = $Commands.$_

}