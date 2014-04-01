require 'coffee-script'
require 'colors'

W = require 'when'
fn = require 'when/function'
nodefn = require 'when/node/function'
async = require 'async'
prompt = require('sync-prompt').prompt
_ = require 'lodash'

ArgsParser = require '../arg_parser'
shipfile = require '../shipfile'
Deployers = require '../deployers'

class DefaultCommand
  constructor: (args, @env) ->
    args = new ArgsParser(args, env)
    @path = args.path
    @config = args.config
    @deployerName = args.deployer

    # default to the first deployer in the config file if the name isn't
    # provided as an arg
    @deployerName ?= Object.keys(@config)[0]
    @deployer = new Deployers[@deployerName](@path)

  run: ->
    @_checkDeployerConfig()
      .then(@_setDeployerConfig)
      .then(@_deployAsync)
      .done (messages) =>
        console.log ''
        console.log 'Deploy Successful!'.green.bold
        console.log ''
        console.log 'Post-Deploy Messages:'.yellow
        console.log "#{msg}" for msg in messages
        cb(null, messages: messages, deployers: @deployers)
      , (err) ->
        error = new Error(err)
        console.error(error.stack.red)
        cb(err)

  ###*
   * @private
  ###
  _checkDeployerConfig: ->
    if @deployer
      @_configureDeployer()

  ###*
   * @private
  ###
  _configureDeployer: ->
    if not @deployer
      return
    if not @config
      return @_createConfWithDeployer()
    if not @_containsDeployer(@)
      return @_addDeployerToConf()

  ###*
   * @private
  ###
  _containsDeployer: (t) ->
    Object.keys(t.config).indexOf(t.deployer) > -1

  ###*
   * @private
  ###
  _createConfWithDeployer: (deferred) ->
    nodefn
      .call(_prompt)
      .done(
        (res) =>
          @config = {}
          @config[@deployer] = res
          shipfile.create(@path)
          shipfile.update(@path, @config)
          deferred.resolve()
        deferred.reject
      )

  ###*
   * @private
  ###
  _addDeployerToConf: (deferred) ->
    nodefn
      .call(_prompt)
      .done(
        (res) =>
          @config[@deployer] = res
          shipfile.update(@path, @config)
          deferred.resolve()
        deferred.reject
      )

  ###*
   * @private
  ###
  _setDeployerConfig: ->
    nodefn
      .call(async.map, @deployers, (d, cb) => d.configure(@config, cb))
      .yield(@deployers)

  ###*
   * @private
  ###
  _deployAsync: (deployers) ->
    nodefn.call async.map, deployers, (d, cb) ->
      if process.env.NODE_ENV is 'test'
        d.mock_deploy(cb)
      else
        d.deploy(cb)

  ###*
   * Ask for an array of config options.
   * @private
   * @return {Array<string>} The array of answers.
  ###
  _prompt: (options) ->
    console.log "please enter the following config details for #{@deployerName.bold}".green
    prompt("#{option}:") for option in options

module.exports = DefaultCommand
