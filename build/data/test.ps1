class tmux {
    hidden [String]$Attached_Session
    [bool]$IsAttached = $false
    [hashtable]$global:Screen = [hashtable]::Synchronized(@{ })
    [hashtable]$Sessions = @{}

    [void] Add_Terminal([String]$Name){
        $this.Screen.Add($Name,@())
    }

    [void] Add_Session([string]$Session, [string]$Name){
        $run = [runspacefactory]::CreateRunspace()
        $run.Open()
        $run.SessionStateProxy.SetVariable('Logging',$this.Screen)
        $pwsh = [PowerShell]::Create().AddScript($Session)
        $pwsh.Runspace = $run
        $this.Sessions.Add($Name,$pwsh)
    }

    [void] Remove_Session([String]$Name){
        $Runspace = Get-Runspace -Name $Name
        $Runspace.close()
        $Runspace.dispose()
    }

    [void] Attach([String]$Name){
        $this.Attached_Session = $Name
        $Session_Count = 0
        $Log_Count = $this.screen.$Name.Count
       While($this.IsAttached -eq $true){
        if ([console]::KeyAvailable) {
            $keys = [Console]::ReadKey($true)
            if($keys.key -eq "D" -and $keys.Modifiers -eq "Shift") {
                $this.IsAttached = $false;
                Clear-Host
                Write-Host "Detached $Name"
                Write-Host "Press Enter For Console Prompt..."
                break
            }
            if($keys.key -eq "A" -and $keys.Modifiers -eq "Shift") {
                Clear-Host
                if( $Session_Count -ge ($this.Screen.Keys.Count - 1)){$Session_Count = 0} 
                else{$Session_Count++}
                Write-Host "Detached $Name"
                $Name = $this.Screen.Keys[$Session_Count]
                Write-Host "Attaching $($Name)"
                $Log_Count = $this.screen.$Name.Count
            }
        } elseif($Log_Count -lt $this.screen.$Name.Count) {
                $this.Screen.$Name | Select -Last 1 | Out-Host
                $Log_Count++
           }
        }
    }
}

$global:Tmux = [tmux]::New()
$Tmux.Add_Terminal("SWARM_Terminal")
$Dir = Convert-Path "."
$Tmux.Add_Session("$Dir\swarm.ps1", "miner")
$Tmux.Sessions.miner.BeginInvoke() | Out-Null

Set-PSReadlineKeyHandler -Chord Shift+A -ScriptBlock {
    Clear-Host
    Write-Host "Attaching Screen"
    $Tmux.IsAttached = $true
    $Tmux.Attach("$($Tmux.Screen.Keys[0])")
}