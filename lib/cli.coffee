path         = require 'path'
pkg          = require '../package.json'
ArgParse     = require('argparse').ArgumentParser
EventEmitter = require('events').EventEmitter
util         = require 'util'
Ship         = require './index'

###*
 * @class  CLI
 * @classdesc command line interface to ship
###

class CLI extends EventEmitter

  ###*
   * Sets up the arguments and program info through argparse
   * @param  {Object} opts - additional options, currently only debug
  ###

  constructor: (opts = {}) ->
    @parser = new ArgParse
      version: pkg.version
      description: pkg.description
      debug: opts.debug ? false

    @parser.addArgument ['-to', '--to'],
      help: "Where you'd like to deploy your site to"

    @parser.addArgument ['-e', '--env'],
      help: "The environment you'd like to deploy to"

    @parser.addArgument ['-c', '--conf'],
      help: "Path to the folder containing your ship.conf file"

    @parser.addArgument ['root'],
      nargs: '?'
      defaultValue: process.cwd()
      help: "Path to the folder you'd like to deploy, defaults to pwd"

  ###*
   * Execute the deploy through the cli with the provided argument, configuring
   * if necessary.
   *
   * @param  {Array|String} args - array or space-separated string of arguments
   * @return {Promise} promise for completed and configured deploy
  ###

  run: (args) ->
    if typeof args is 'string' then args = args.split(' ')
    args = @parser.parseArgs(args)
    try ship = new Ship
      root:     args.root
      deployer: args.to
      env:      args.env
      conf:     args.conf
    catch err then return @emit('err', err)

    if not ship.is_configured()
      ship.config_prompt().with(ship)
        .then(-> ship.write_config())
        .then(deploy.bind(@, ship))
    else
      deploy.call(@, ship)

  ###*
   * Run a deploy, monitor the progress, and finish up emitting the right info
   * through the cli.
   *
   * @param  {Ship} ship - a Ship instance
   * @return {Promise} promise for a finished deploy
  ###

  deploy = (ship) ->
    ship.deploy()
      .progress(@emit.bind(@, 'info'))
      .done (res) =>
        @emit("success", "deploy to #{res.deployer} successful!")
        if res.url then @emit("success", "Live at: #{res.url}")
      , @emit.bind(@, 'err')

module.exports = CLI
