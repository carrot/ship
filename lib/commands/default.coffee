require 'coffee-script'
require 'colors'

W = require 'when'
fn = require 'when/function'
nodefn = require 'when/node/function'
async = require 'async'
prompt = require 'prompt'
_ = require 'lodash'

arg_parser = require '../arg_parser'
prompt = require '../prompt'
shipfile = require '../shipfile'
Deployers = require '../deployers'

# TODO: better error handling
class DefaultCommand

  constructor: (args, @env) ->
    @args = arg_parser(args, env)
    if @args instanceof Error then return @

    @path = @args.path
    @config = @args.config
    @deployer = @args.deployer

  run: (cb) ->
    if @args instanceof Error then return cb(@args.toString())

    deployer_names = if @deployer then [@deployer] else Object.keys(@config)
    deployer_names = _.without(deployer_names, 'ignore')
    @deployers = deployer_names.map((name) => new Deployers[name](@path))

    check_deployer_config.call(@)
      .then(set_deployer_config.bind(@))
      .then(deploy_async)
      .done (messages) =>
        console.log ''
        console.log 'Deploy Successful!'.green.bold
        console.log ''
        console.log 'Post-Deploy Messages:'.yellow
        console.log "#{msg}" for msg in messages
        cb(null, { messages: messages, deployers: @deployers })
      , (err) ->
        error = new Error(err)
        console.error(error.stack.red)
        cb(err)

  #
  # @api private
  #

  check_deployer_config = ->
    deferred = W.defer()
    if @deployer
      configure_deployer.call(@, deferred)
    else
      deferred.resolve()
    return deferred.promise

  configure_deployer = (deferred) ->
    if not @deployer
      return deferred.resolve()
    if not @config
      return create_conf_with_deployer.call(@, deferred)
    if not contains_deployer(@)
      return add_deployer_to_conf.call(@, deferred)
    deferred.resolve()

  contains_deployer = (t) ->
    Object.keys(t.config).indexOf(t.deployer) > -1

  create_conf_with_deployer = (deferred) ->
    nodefn.call(prompt.bind(@)).done (res) =>
      @config = {}
      @config[@deployer] = res
      shipfile.create(@path)
      shipfile.update(@path, @config)
      deferred.resolve()
    , deferred.reject

  add_deployer_to_conf = (deferred) ->
    nodefn.call(prompt.bind(@)).done (res) =>
      @config[@deployer] = res
      shipfile.update(@path, @config)
      deferred.resolve()
    , deferred.reject

  set_deployer_config = ->
    nodefn
      .call(async.map, @deployers, (d, cb) => d.configure(@config, cb))
      .yield(@deployers)

  deploy_async = (deployers) ->
    nodefn.call async.map, deployers, (d, cb) ->
      if process.env.NODE_ENV == 'test' then d.mock_deploy(cb) else d.deploy(cb)

module.exports = DefaultCommand
