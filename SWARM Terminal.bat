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
ECHO       clear_profits (deletes all profit data from pools)
ECHO       clear_watts (removes all saved wattometer readings)
ECHO
ECHO       Note- all these commands can be ran and auto refreshed
ECHO       Using 'nview' command
ECHO       Example:
ECHO
ECHO       nview -n 30 -OnChange get stats 5
ECHO
ECHO       This command will run get stats 5 every 30 seconds
ECHO       and refresh screen if data has changed.
ECHO       get stats 5 will get top 5 stats.
ECHO       get stats lite will get stats in Cell-Phone
ECHO       friendly format (List format)
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
