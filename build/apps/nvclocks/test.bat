:: Arguments
:: -i = index of GPU.
:: -p = power limit setting: value1,value2. value1 is what you want you watts to be. value2 is max watt rating of gpu.
:: 	Example -p 180,250  would mean that the max power limit of gpu is 250 watts, and you want the pl to be 180.
:: -s = fan speed. Sets fan speed

:: Correct Output
:: This is what it should say if working
::
::
:: GPU index: 0
:: Can Power Limit Be Changed: True
:: Max PowerLimit % is: 100
:: Watt Desired: 65
:: Watt Maximum: 75
:: Suggested Power Limit: 87
:: Old PL: 87
:: New PL: 87
:: Press any key to exit ....

NVClocks -i 0 -s 100
cmd.exe