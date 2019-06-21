function Global:Get-TableFromJson($X) {
    $bar = get-content -raw $X | ConvertFrom-Json

    # Build an ordered hashtable of the property-value pairs.
    $sortedProps = [ordered] @{}
    Get-Member -Type  NoteProperty -InputObject $bar | Sort-Object Name |
      % { $sortedProps[$_.Name] = $bar.$($_.Name) }
    
    # Create a new object that receives the sorted properties.
    $barWithSortedProperties = New-Object PSCustomObject
    Add-Member -InputObject $barWithSortedProperties -NotePropertyMembers $sortedProps
    $sortedProps
    }