# ship
[![npm](https://badge.fury.io/js/ship.png)](http://badge.fury.io/js/ship)
[![tests](https://travis-ci.org/carrot/ship.png?branch=master)](https://travis-ci.org/carrot/ship)
[![dependencies](https://david-dm.org/carrot/ship.png)](https://david-dm.org/carrot/ship)

Multi-platform deployment with node.

> **Note:** This library is _incomplete_, still in development, and you should not attempt to use it for anything, yet. As soon as it's ready, this note will be removed, and releases will be tagged.

## why?
If you often need to deploy files to different platforms, or you have an app or library written in node and would like to give your users the ability to deploy files to a variety of platforms, ship is probably what you are looking for.

## deployers

### working
- [Amazon S3](lib/deployers/s3) - `s3`
- [Github Pages](lib/deployers/gh-pages) - `gh-pages`

### in-progress
- [Heroku](lib/deployers/heroku) - `heroku`
- [Nodejitsu](lib/deployers/nodejitsu) - `nodejitsu`
- [FTP](lib/deployers/ftp) - `ftp`
- [Dropbox](lib/deployers/dropbox) - `dropbox`
- [Linux VPS](lib/deployers/vps) - `vps`

Ship is also extendable, so if there's another platforms you'd like to deploy to, the project structure is easy to understand, and you can write a deployer, send a pull request, and we'd be happy to include it.

## installation
`npm install ship -g`

## usage
Ship's primary interface is through the command line. This is what you'd use normally when working with ship, or if you're using ship within another (non-JS based) script. If you'd like to integrate it into your node app, see the [Javascript API](#javascript-api).

The command line interface is simple, and every part of ship can be controlled through the CLI options (which map 1:1 with [ship opts files](#opts-files)).

```
ship [deployer] [opts] [opts_file='./ship.opts']
```

### project-root

### source-dir

### ignore
If you'd like to ignore a file or folder from the deploy process, just add an `--ignore` array to the `ship.opts` file and fill it with [minimatch-compatible](https://github.com/isaacs/minimatch) strings. `ship*.opts` is ignored automatically because you do not want to deploy those files, ever.

## opts files
It would be a real pain to have to type in all the configuration info each time you deploy. So, ship supports `.opts` files. These are the same format as the command line args, so there's no configuration language to learn. For example, the opts file for deploying to s3 would look something like this:

```
s3
--access-key xxxx
--secret-key xxxx
```

If you use `ship` without specifying a deployer, `./ship.opts` will be loaded automatically. So running `ship` with the example file above would be the equilivant of running `ship s3 --access-key xxxx --secret-key xxxx`.

If you have a separate deployment for production and staging, you can specify them in separate files and call them with `ship ship.produciton.opts` and `ship ship.staging.opts`.

You can even mix and match config files with args. For example, if you wanted to deploy a different folder than you normally would, during one particular deploy, you could do `ship --source-dir=./public2 ship.staging.opts` and the `--source-dir` arg will take precidence over the default one.

## JavaScript API
The interface is very straightforward:

```coffee
ship = require 'ship'
ship.deploy(
  deployer: 'gh-pages'
  projectRoot: './'
).then(->
  console.log 'done'
)
```

See [lib/index.coffee](./blob/master/lib/index.coffee) for the fully documented functions.
