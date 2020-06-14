$host.ui.RawUI.WindowTitle = 'OC-Start';
Invoke-Expression '.\inspector\nvidiaInspector.exe -setPowerTarget:0,136  -setPowerTarget:1,142  -setBaseClockOffset:0,0,100  -setBaseClockOffset:1,0,100  -setMemoryClockOffset:0,0,500  -setMemoryClockOffset:1,0,500  -forcepstate:0,0 '
Invoke-Expression '.\nvfans\nvfans.exe --index 0 --speed 100'
Invoke-Expression '.\nvfans\nvfans.exe --index 1 --speed 100'
