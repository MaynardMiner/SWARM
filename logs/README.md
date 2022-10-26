# SWARM LOGS

## SWARM logs
Swarm will by default log its runtime. Swarm saves logs as:

```swarm__[hour]_[minute]__[day]__[Month]__[year].log```

If Swarm detects it has ran for 24 hours, it will create a new log using the same schema above based
on the date the log rolls over.

SWARM also checks the dates on all previous logs. Any log 5 days or old is automatically deleted to
preserve disk usage.

## Miner logs
SWARM does its best to capture standardoutput of all miners. In linux, this is relatively easy to do,
but in Windows it is a constant challenge.

Whatever miner is running, the output of the miner is sent to [MINER_NAME].log, which means if miner is
gminer-a-1, the log would be named gminer-a-1.log.

When miners first start (when no miners for that device type is running), SWARM will check the log
of that miner. If there is more than 10,000 lines of output, it will trim half the log. This is because
some miners will start the log fresh, while other miners will continue to append the selected log. This is
done so that miner log files do not get too large of a size, but you will still be able to review the most
recent running data (at least the last 5000 lines of the miner).
