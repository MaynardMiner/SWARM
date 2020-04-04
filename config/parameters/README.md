# Parameter Configuration

There can be up to three different files here, each has a specific purpose.


## default.json
* Comes with SWARM from start.
* Should never be modified. 
* Is the basic default settings.
* If a user does not specify an argument, the setting here will be used.

## commandline.json
* Created when launched.
* Contains starting arguments for user.
* If user did not specify a parameter- SWARM will use from default.json.
* All parameters must be listed here.

## newarguments.json
* Created from remote configuration/configuration help-me
* Has highest precedence- Will always use this config first.
* Is effectively the user's flight sheet.

# Alternative: config.json

If user is running SWARM through h-run.sh (HiveOS launch), and they are using a
.json config in fligh sheet- none of these files are used.
Instead config.json is created in main directory, and is what is used for parameters.
This is only if .json is sent in flight sheet instead of arguments.
