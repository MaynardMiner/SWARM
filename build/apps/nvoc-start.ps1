$host.ui.RawUI.WindowTitle = 'OC-Start';
Invoke-Expression '.\nvidiaInspector.exe -setBaseClockOffset:0,0,100  -setBaseClockOffset:1,0,100  -setBaseClockOffset:2,0,100  -setFanSpeed:0,75  -setFanSpeed:1,75  -setFanSpeed:2,75  -setMemoryClockOffset:0,0,500  -setMemoryClockOffset:1,0,500  -setMemoryClockOffset:2,0,500  -setPowerTarget:0,75  -setPowerTarget:1,75  -setPowerTarget:2,75 '
