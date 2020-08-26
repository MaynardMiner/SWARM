$host.ui.RawUI.WindowTitle = 'OC-Start';
Invoke-Expression '.\inspector\nvidiaInspector.exe -setBaseClockOffset:0,0,100  -setMemoryClockOffset:0,0,500  -forcepstate:0,0 '
Invoke-Expression '.\nvfans\nvfans.exe -i 0 -s 100'
Invoke-Expression '.\nvclocks\NVClocks.exe -i 0 -p 175,200'
