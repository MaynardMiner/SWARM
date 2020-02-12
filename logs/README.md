# SWARM LOGS

## SWARM logs
Swarm will by default log its runtime. The logs are saved in hourly timeframes, with miner1.log being the first.
Once an hour has passed- miner2.log will be created, and SWARM will be logged there. This allows you to quickly
view an hour-by-hour breakdown of SWARM runtime.

Since there are multiple log files, they sometimes will overlap, such as when you restart SWARM. When attempting
to find the current (most recent) log, the log denoted with -active is the log that is either being used,
or was being used.

So if you have the following

miner1.log
miner2.log
miner3.log
miner4-active.log
miner5.log
miner6.log

This means that miner4-active is the current active log. Every log past it is likely present due to a restart
of some form, or from a rollover of logs.

The logs will automatically roll over every 12 hours. This means that the maximum number in logs will be
miner12.log. If the logs rollover, SWARM rotates back to miner1.log.


## Crash Reports

Whenever SWARM is started right after, or within 10 minutes of a reboot- SWARM generates a crash_report.

The crash reports copy the current logs at the time (before they are all reset). The crash report
also copys the contents of the debug folder at the time, which may contain information on how 
to fix issues.

SWARM then compresses that folder to save space. After 12 hours of successful runtime- It will
delete these crash reports.

## Miner logs
SWARM does its best to capture standardoutput of all miners. In linux, this is relatively easy to do,
but in Windows it is a constant challenge.

Whatever miner is running, the output of the miner is sent to [GROUP].log, which means if using NVIDIA1
that would be NVIDIA1.log

This data can be pulled remotely with the command ``get screen [GROUP]``, which will show you as much of
the log it can print out and send remotely.