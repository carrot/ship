Linux VPS
---------

This deployer will push files via SFTP to any Linux-based VPS. It also allows the opportunity to run a basic script both before and after the deploy, both remotely and locally. Note that this deployer does not have handling for passwords, so you should add your ssh key to the VPS so that you don't need one. You should do this anyway though.

This deployer performs zero-downtime deploys, which is achieved by deploying to a different directory and once finished swapping it out for the target. Ship stores it's "releases directory" at `~/.ship-releases`, so the target directory will always be a symlink to here.

### Config Values

- **username**: the username you use to log in, defaults to `root`
- **host**: hostname of the machine. this can be an IP or domain name
- **port**: port that you want to log in through, defaults to `22`
- **target**: directory on the remote machine that you want to deploy files to
- **before**: path to a command file to be run before deploy, details below
- **after**: path to a command file to be run after deploy, details below

### Before/After Scripts

In order to make what can be a very complex deployment as simple as possible, if you want to you can specify the path to a js or coffeescript file containing keys for `local` and/or `remote` with the values being strings of commands you'd like to run as the `before` or `after` config values. This means you can run anything from the command line, locally or remotely, before or after the deployment, which is awesome. If you'd like to run multiple commands, you can separate them with newlines. Coffeescript is much better and cleaner for this type of thing because it has real multiline strings, but javascript can work too if you aren't into coffee. Examples below.

**Coffeescript:**

```coffee
local: """
  mkdir foobar
  echo 'wow look at how cool I am'
"""

remote: """
  wall 'Hey guys, just deployed with ship!'
"""
```

**Javascript:**

```js
local: [
  "mkdir foobar",
  "echo 'wow look at how cool I am"
].join('\n')

remote: "wall 'Hey guys, I just deployed with ship!"
```

These files are required through node.js, so you have the full power of javascript available to you here. The only thing ship looks for is `exports.local` and `exports.remote` -- if you want to work with other variables, other pieces of logic, or even require things, you can do so freely.

In addition, if you need to complete asynchrnous tasks, or need a function wrapper for some reason, you can return a function that returns a string or a promise for a string, and this will still work correctly. For example:

```coffee
rest = require 'rest'

exports.local = ->
  rest('http://google.com').then((res) -> res.entity)
```

Please don't run the entire html of `google.com` from the command line, this is just an example. But you get the idea.
