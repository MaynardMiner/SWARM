@Echo Off
cd /D %~dp0
ECHO You can run terminal commands here.
ECHO Commands such as:
echo.       
echo.       
ECHO       get stats (gets miner stats)
ECHO       get active (gets mining history)
ECHO       get help (shows most commands and usage)
ECHO       bench bans (resets all AI bans)
ECHO       version query (lists all miners and their versions)
ECHO       version update (updates a current miner)
ECHO       swarm_help (starts configuration help)
echo.       
echo.       
echo.       
ECHO For full command list, see: https://github.com/MaynardMiner/SWARM/wiki
echo.       
echo.       
echo.       
ECHO Starting CMD.exe
echo.       
echo.      
echo.     
cmd.exe /D %~dp0
