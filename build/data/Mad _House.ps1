#
# Adventure House Game v4 # By Jose Barreto
# Written as a PowerShell Example in March 2015
# 
#
# Defines the array with information about Rooms
# 
[Array] $Rooms = ( 
 #   Name                 Description                           N  S  E  W  U  D 
(00,"Exit!",             "Exit!"                               ,99,99,99,01,99,99), 
(01,"Entrance Hall",     "entrance hall. The door is locked"   ,10,02,99,99,99,99), 
(02,"Downstairs Hall",   "hall at the bottom of the stairs"    ,01,04,03,99,11,99), 
(03,"Guest Bathroom",    "small guest bathroom downstaris"     ,99,99,05,02,99,99), 
(04,"Living Room",       "living room on the southeast side"   ,02,99,99,05,99,99), 
(05,"Family Room",       "family room with a large TV"         ,06,99,02,99,99,99), 
(06,"Nook",              "nook with a small dining table"      ,07,05,99,24,99,99), 
(07,"Kitchen",           "kitchen with a large granite counter",08,06,99,99,99,99), 
(08,"Kitchen Hall",      "small hall with two large trash cans",99,07,10,09,99,99), 
(09,"Garage",            "garage, the big door is closed"      ,99,99,08,99,99,99), 
(10,"Dining Room",       "dining room on the northeast side"   ,99,01,99,08,99,99), 
(11,"Upstairs Hall",     "hall at the top of the stairs"       ,99,12,16,13,99,02), 
(12,"Upper East Hall",   "hall with two tables and computers"  ,11,15,99,99,99,99), 
(13,"Upper North Hall",  "hall with a large closet"            ,18,14,11,17,99,99), 
(14,"Upper West Hall",   "hall with a small closet"            ,13,23,99,22,99,99), 
(15,"Guest Room",        "guest room with a queen size bed"    ,12,99,99,99,99,99), 
(16,"Laundry",           "laundry room with a washer and dryer",99,99,99,11,99,99), 
(17,"Main Bathroom",     "main bathroom with a bathtub"        ,99,99,13,99,99,99), 
(18,"Master Bedroom",    "master bedroom with a king size bed" ,21,13,19,99,99,99), 
(19,"Master Closet",     "long and narrow walk-in closet"      ,99,99,99,18,20,99), 
(20,"Attic",             "attic, it is dark in here"           ,99,99,99,99,99,19), 
(21,"Master BathRoom",   "master bedroom with a shower and tub",99,18,99,99,99,99), 
(22,"Children's Room",   "children's room with twin beds"      ,99,99,14,99,99,99), 
(23,"Entertainment Room","play room with games and toys"       ,14,99,99,99,99,99), 
(24,"Patio",             "wooden patio. A key on the floor"    ,99,99,06,99,99,99) 
)  
#
# Entrance Hall is a special room we refer to a lot
# 
[Int] $EntranceHall = 01 
#
# Defines the array with information about objects (Inventory)
# 
[Array] $Inventory = (
 # Name/Loc  Description/Action text
("BREAD", "A small loaf of bread. Not quite a lunch, too big for a snack.",
  06,     "It's too big for a snack. Maybe later, for lunch."),
("BUGLE", "You were never very good with instruments.",
  20,     "You try to no avail to produce something that could constitute music."),
("APPLE", "A nice, red fruit that looks rather apetizing.",
  07,     "Tastes just as good as it looked."),
("KEY",   "A shiny, aesthetically pleasing key. Must open something.",
  24,     "The key fits perfectly and the door unlocked with some effort."),
("WAND",  "A small wooden wand.",
  17,     "You wave the wand and the room fades for a second."),
("PIE",   "A small slice of apple pie. Mouthwatering.",
  10,     "A little cold, but there never really a good reason to turn down pie.")
) 
#
# Takes the name of an object and returns the index to it in the Inventory
# If returning 99, that means an object with that name does not exist
# 
Function Get-InventoryIndex([String] $Name) {
    $Found = 99
    0..($Inventory.Count-1) | % { If ($Inventory[$_][0] -eq $Name) { $Found = $_ } }
    Return $Found
} 
#
# Takes a room number and returns number of objects in it
# 
Function Get-InventoryCount([int] $InRoom) {
    $Found = 0
    0..($Inventory.Count-1) | % { If ($Inventory[$_][2] -eq $InRoom) { $Found++ } }
    Return $Found
} 
#
# Takes a room number and returns a string with the names of the objects in it
# 
Function Get-InventoryItems([int] $InRoom) {
    $Items = ""
    0..($Inventory.Count-1) | % { If ($Inventory[$_][2] -eq $InRoom) { 
        $Items += $Inventory[$_][0]+", " } 
    }
    If ($Items -eq "") {$Items = "None"}
    else { $Items = $Items.Remove($Items.Length - 2) }
    Return $Items
} 
#
# Defines array with messages when unable to move a certain direction
# 
[array] $NeutralMessages = ( 
    "There is no way to go @ from here.",
    "You can't go @.",
    "There's nothing @ from here." 
    )
    [array] $UpMessages = (
    "You can't go through the roof.",
    "There's a roof in the way."
    )
    [array] $DownMessages = (
    "You can't dig through the floor.",
    "You sadly aren't a mole."
    )
    [array] $CardinalMessages = (
    "There's a wall there to the @.",
    "There's no path leading @ from here."
) 
#
# Returns a message to show when a user cannot go a certain direction
# Uses the message arrays defined previously
# 
Function Get-WrongDirection ([String] $Direction) {
 if ($Direction -eq "up") { $Messages = $NeutralMessages + $UpMessages }
 elseif ($Direction -eq "down") { $Messages = $NeutralMessages + $DownMessages }
 else { $Messages = $NeutralMessages + $CardinalMessages }
 $Number = Get-Random ($Messages.Count)
 $MessageString = $Messages[$Number]
 return $MessageString.Replace("@",$Direction)
} 
#
# Health starts with 100. Health changes in steps of 2
# 
[Int] $Health = 100
[Int] $HealthStep = 2 
#
# Takes the Health percent and turns into a message
# 
Function Get-HealthReport ([int] $HealthPercent) {
    if ( $HealthPercent -gt 70) { $HealthText = "Great!" }
    elseif ( $HealthPercent -gt 40 ) { $HealthText = "Okay." }
    elseif ( $HealthPercent -gt 10 ) { $HealthText = "Bad." }
    else { $HealthText = "Horrible!" }
    return $HealthText
} 
#
# Starts in room 20 (the attic), defines initial message
# 
[Int] $Room = 20
[String] $Message = "Find the way out of this house." 
#
# Main loop. Repeat until user finds Room 0 (exit)
# 
While ($Room -ne 0) { 
    #
    # Gets information for current room
    # 
    $Name  = $Rooms[$Room][1]
    $Desc  = $Rooms[$Room][2]
    $North = $Rooms[$Room][3]
    $South = $Rooms[$Room][4]
    $East  = $Rooms[$Room][5]
    $West  = $Rooms[$Room][6]
    $Up    = $Rooms[$Room][7]
    $Down  = $Rooms[$Room][8]  
    #
    # Finds which commands are available here
    # 
    $Available = "[Q]uit"
    If ($North -ne 99) { $Available += ", [N]orth" }
    If ($South -ne 99) { $Available += ", [S]outh" }
    If ($East  -ne 99) { $Available += ", [E]ast" }
    If ($West  -ne 99) { $Available += ", [W]est" }
    If ($Up    -ne 99) { $Available += ", [U]p" }
    If ($Down  -ne 99) { $Available += ", [D]own" }
    If (Get-InventoryCount($Room) -gt 0) { $Available+= ", [P]ick " }
    If (Get-InventoryCount(0) -gt 0 ) { $Available+= ", [R]elease, [I]nspect, [A]pply " } 
    #
    # Shows temporary message. Message is cleared after each command
    # 
    if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
    Write-Host $Message
    $Message=""  
    #
    # Shows room information
    # 
    Write-Host
    Write-Host -ForegroundColor Yellow $Name
    Write-Host "You are at the $Desc"
    $Items = Get-InventoryItems($Room)
    Write-Host "Items in this room : $Items" 
    #
    # Shows user health and inventory
    # 
    Write-Host
    $CurrentHealth = Get-HealthReport ($Health)
    Write-Host "You are feeling $CurrentHealth ($Health%) "
    $Items = Get-InventoryItems(0)
    Write-Host "You have : $Items"
    Write-Host 
    #
    # Asks for input. 
    # $Action is first letter of first word.
    # $Item is the second word
    # 
    Write-Host -ForegroundColor Green "Commands : $Available ? " -NoNewline
    $Cmd = Read-Host
    $Cmd = $Cmd.ToUpper()
    $Action = $Cmd[0]
    $Item = $Cmd.Split(" ")[1]  
    #
    # Main "switch" statement that interprets commands
    # Starting with the 6 direction commands
    # 
    Switch ($Action) { 
    "N" { If ($North -ne 99) { $Room = $North } 
          else {$Message = Get-WrongDirection ( "north" )}
        } 
    "S" { If ($South -ne 99) { $Room = $South } 
          else {$Message = Get-WrongDirection ( "south" ) }
        } 
    "E" { If ($East  -ne 99) { $Room = $East  } 
          else {$Message = Get-WrongDirection ( "east" ) }
        } 
    "W" { If ($West  -ne 99) { $Room = $West  } 
          else {$Message = Get-WrongDirection ( "west" ) }
        } 
    "U" { If ($Up    -ne 99) { $Room = $Up    } 
          else {$Message = Get-WrongDirection ( "up" ) }
        } 
    "D" { If ($Down  -ne 99) { $Room = $Down  } 
          else {$Message = Get-WrongDirection ( "down" ) }
        } 
    #
    # [I]nspect command
    # 
    "I" { if ($item -eq "" -or $item -eq $null) { $Message = "Inspect what?" } 
          else {
              $ItemIndex = Get-InventoryIndex($Item)
              if ($ItemIndex -eq 99) { $Message = "I have no clue what '$Item' is." }
              else {
                  $ItemRoom =  $Inventory[$ItemIndex][2]
                  If ($ItemRoom -eq $Room) { $Message = "Can't see well. Maybe if I pick it up." }
                  elseIf ($ItemRoom -eq 00) { $Message = $Inventory[$ItemIndex][1] }
                  else { $Message = "There is no '$Item' here." }
              } #end if $ItemIndex -eq 99
           } #end $item -eq ""
        } #end "I" 
    #
    # [P]ick command
    # 
    "P" { if ($item -eq "" -or $item -eq $null) { $Message = "Pick what?" } 
          else {
              $ItemIndex = Get-InventoryIndex($Item)
              if ($ItemIndex -eq 99) { $Message = "I have no clue what '$Item' is." }
              else {
                  $ItemRoom =  $Inventory[$ItemIndex][2]
                  if ($ItemRoom -eq 00) { $Message = "You already have the '$Item'." }
                  elseif ($ItemRoom -ne $Room) { $Message = "There is no '$Item' here." }
                  else { 
                      $Inventory[$ItemIndex][2] = 0
                      $Message = "You picked the '$Item'."
                  }
              } #end if $ItemIndex -eq 99
           } #end $item -eq ""
        } #end "I" 
    #
    # [R]elease command
    # 
    "R" { if ($item -eq "" -or $item -eq $null) { $Message = "Release what?" } 
          else {
              $ItemIndex = Get-InventoryIndex($Item)
              if ($ItemIndex -eq 99) { $Message = "I have no clue what '$Item' is." }
              else {
                  $ItemRoom =  $Inventory[$ItemIndex][2]
                  if ($ItemRoom -ne 00) { $Message = "You don't have the '$Item'." }
                  else { 
                      $Inventory[$ItemIndex][2] = $Room
                      $Message = "You dropped the '$Item'."
                  }
              } #end if $ItemIndex -eq 99
           } #end $item -eq ""
        } #end "R" 
    #
    # [A]pply command
    # 
    "A" { if ($item -eq "" -or $item -eq $null) { $Message = "Apply what?" } 
          else {
              $ItemIndex = Get-InventoryIndex($Item)
              if ($ItemIndex -eq 99) { $Message = "I have no clue what '$Item' is." }
              else {
                  $ItemRoom =  $Inventory[$ItemIndex][2]
                  if ($ItemRoom -ne 00) { $Message = "You don't have the '$Item'." }
                  else { 
                     $Message = $Inventory[$ItemIndex][3] 
                     Switch ($Item) {
                     "KEY"   { if ($Room -ne $EntranceHall) { $Message = "The key doesn't fit anywhere here." }
                               elseif ($Rooms[$EntranceHall][5] -eq 99 ) {
                                   $Rooms[$EntranceHall][2] = "hall by the entrance. The key unlocked the door."
                                   $Rooms[$EntranceHall][5] = 0 }
                               else { $Message = "You already unlocked the door a moment ago." }
                             } #end key
                     "WAND"  { $Room = (Get-Random ($Rooms.Count -1)) + 1 }
                     "BREAD" { If ($Health -le 30 ) {
                                   $Health = 110 + $HealthStep
                                   $Inventory[$ItemIndex][2] = 99 
                                   $Message = "Like I thought, it was a pretty good lunch." 
                               }
                             }
                     "APPLE" { $Health += 50
                               If ($Health -gt (100 + $HealthStep) ) 
                               {$Health = 100 + $HealthStep }
                               $Inventory[$ItemIndex][2] = 99 
                             }
                     "PIE"   { $Health = 100 + $HealthStep
                               $Inventory[$ItemIndex][2] = 99 
                             }
                     } #end switch $item
                  } # if $ItemRoom -ne 00
              } #end if $ItemRoom -eq 99
           } #end $item -eq ""
        } #end "R" 
    #
    # [Q]uit command
    # 
    "Q" { $Room = 0 } 
    default { $Message = "I do not know how to " + $Cmd } 
    } #end switch $Action 
    #
    # Decrease health, check if it reached zero
    # 
    $Health -= $HealthStep
    If ($Health -le 0) {
        $Room = 0
        $Action = "Q"
        Write-Host "You starved to death."
    } 
} #end while 
#
# Final message
# 
if ($Action -ne "Q") { Write-Host "You found the way out. Congratulations!" }
                else { Write-Host "Better luck next time..." }
