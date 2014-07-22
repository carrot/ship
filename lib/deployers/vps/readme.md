Linux VPS
---------

> **Note:** This deployer is not functional at the moment, it's a work in progress.

Deploys files to a server via ssh. Allows automated local and remote command execution before and after deploys. Deploys are zero-downtime and the previous 10 deploys are backed up.

### Config Values

**user**: user to log in to the server with
**host**: ip address or hostname of the server
**target**: folder you wish to deploy
**remote_target**: path you wish to deploy to on the server
**key**: _(optional)_ path to .pem
**port**: _(optional)_ port to connect through. defaults to `21`
**before**: _(optional)_ path to before [hook script](#)
**after**: _(optional)_ path to after [hook script](#)

### Hook Scripts

Ship has a very simple system for automated script running before and after deploys. To start, create a `.js` or `.coffee` file (examples will be in coffeescript) at any path you'd like. We often will use a `deploy` folder at the project root. In that file, just list out the commands you'd like to run as a string under a `local` and/or `remote` object. For example:

```coffee
local: """
  svgo -f #{target}/img
"""

remote: """
  wall 'here comes a deploy!'
  touch /foo
"""
```

This small before script would optimize our svgs locally, and notify all users on the remote machine that a deploy is about to hit, then make a file called foo at the root. Silly, sure, but you might have better uses. The same exact formatting can be used for an after script.

You may have also noticed that there's at least one variable available to us. It turns out there are a few that you might find to be useful, which are listed below:

- **target**: path to the local folder you want to deploy
- **remote_target**: path to the remote destination of your deploys

### Deploy Structure

Ship adopts the convention seen in [capistrano](https://github.com/capistrano/capistrano/wiki/2.x-from-the-beginning#deployment-directory-structure) -- each deploy is added to a `releases` folder and symlinked to a folder called `current` after the files are finished transferring. This means no-downtime deploys and a history of releases is kept.

### Want More?

What ship offers is a very simple and minimal way to deploy files. If you are hungry for more advanced functionality like roles, tasks and such, we would encourage you to check out [other deployment solutions](http://capistranorb.com). Ship does not aim to replicate tools that are meant for handling more complex VPS deployments, it's just a simple baseline for getting files from one place to another.

That being said, if you are really stuck on using ship for more complex deployments, you could always write a script in whatever language you want locally or remotely that does whatever you want and run it with a before or after hook script. But all ship will do is run it for you, not handle any special tasks or offer a DSL for doing this more easily.
