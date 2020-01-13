Using namespace System;
using module ".\maintenance.psm1";
using module ".\devices.psm1";
using module ".\logging.psm1";


class SWARM {
    static [void] main([String[]]$arguments) {

        ## Start Logger
        $Global:Log = [Logging]::New()

        ## Nvidia NVML
        [NVIDIA]::get_nvml()
    
        ## Folder Check/Generation and Maintenence
        $Global:Log.screen('Checking For Directories And Making As Required')
        [startup]::make_folders();

        ## Build Rig
        $Global:Rig = [RIG]::New()
    }
}