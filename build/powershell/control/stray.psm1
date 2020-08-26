
function global:Stop-Stray($X) {
    $proc = Get-Process | Where-Object  id -eq $X.ParentProcessID  ## Want to close powershell window they are in.
    if ($proc) { $proc.CloseMainWindow() | Out-Null }
    log "waiting 5 seconds to confirm $($X.name) window has closed..." -ForeGroundColor Yellow
    Start-Sleep -S 3
    ## Check to see if process closed
    if ($proc.HasExited -eq $false) {
        ## Try forcefully
        log "trying to force process to close..." -ForeGroundColor Red
        Stop-Process -Id $Proc.Id
        ## Wait 3 seconds
        Start-Sleep -S 3
        if ($proc.HasExited -eq $false) {
            log "MINER WILL NOT CLOSE, MOVING ON!" -ForeGroundColor Red
        }
    }
}

function global:Stop-StrayMiners {
    param(
        [Parameter(mandatory = $false)]
        [switch]$Startup
    )

    ## Get Process, and sort them.
    $processes = (Get-CIMInstance win32_process | Where-Object  { $_.ProcessName -eq 'pwsh.exe' } | Select-Object processid)
    $subprocesses = $processes.processid | ForEach-Object { $id = $_; Get-CimInstance Win32_Process | Where-Object  { $_.ParentProcessId -eq $id } }

    ## Get Miner executable names
    $Exec_list = @()
    if ($startup) {
        Global:Add-Module "$($(vars).build)\miners.psm1"
        if ($(arg).Type -like "*CPU*") { create cpu (Global:Get-minerfiles -Types "CPU") }
        if ($(arg).Type -like "*NVIDIA*") { create nvidia (Global:Get-minerfiles -Types "NVIDIA") }
        if ($(arg).Type -like "*AMD*") { create amd (Global:Get-minerfiles -Types "AMD") }
    }
    if ($(vars).cpu) { $(vars).cpu.PSObject.Properties.name | Foreach-Object { $Exec_List += (Split-Path $(vars).cpu.$_.CPU -Leaf) } }
    if ($(vars).nvidia) {
        $(vars).nvidia.PSObject.Properties.name | Foreach-Object {
            $Exec_List += (Split-Path $(vars).nvidia.$_.NVIDIA1 -Leaf)
            $Exec_List += (Split-Path $(vars).nvidia.$_.NVIDIA2 -Leaf)
            $Exec_List += (Split-Path $(vars).nvidia.$_.NVIDIA3 -Leaf)
        } 
    }
    if ($(vars).amd) {
        $(vars).amd.PSObject.Properties.name | Foreach-Object { 
            $Exec_List += (Split-Path $(vars).amd.$_.AMD1 -Leaf); 
            $Exec_List += (Split-Path $(vars).amd.$_.AMD2 -Leaf);
            $Exec_List += (Split-Path $(vars).amd.$_.AMD3 -Leaf); 
        } 
    }

    ## Get subprocesses that could potentially be a stray miner
    $subprocesses = $subprocesses | Where-Object  { $_.Name -in $Exec_list }

    ## Startup- Stop all miners (none should be running now)
    if ($subprocesses) {
        ## Startup- Stop all miners (none should be running now)
        if ($Startup) {
            log "Swarm detected miners running...Attempting to close them." -ForeGroundColor Yellow
            $subprocesses | Foreach-Object {
                Global:Stop-Stray $_
            }
        }
        else {
            ## Periodic Check. Only close miners that are not active
            $subprocesses = $subprocesses | Where-Object  { $_.ParentProcessID -notin $(vars).BestActiveMiners.XProcess.Id }
            if ($subprocesses) {
                log "Swarm detected a stray miner that didn't close when commanded...Attempting to close it." -ForeGroundColor Yellow
                $subprocesses | Foreach-Object {
                    Global:Stop-Stray $_
                }
            }    
        }
    }
}