require 'coffee-script'
require 'colors'

W = require 'when'
fn = require 'when/function'
nodefn = require 'when/node/function'
async = require 'async'
prompt = require 'prompt'

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
    @deployers = deployer_names.map((name) => new Deployers[name](@path))

    check_deployer_config.call(@)
      .then(set_deployer_config.bind(@))
      .then(deploy_async)
      .then (messages) =>
        console.log ''
        console.log 'Deploy Successful!'.green.bold
        console.log ''
        console.log 'Post-Deploy Messages:'.yellow
        console.log "#{msg}" for msg in messages
        cb(null, { messages: messages, deployers: @deployers })
      , (err) ->
        console.error("#{err}".red)
        cb(err)

  # 
  # @api private
  # 
  
  sync = (func, ctx) -> fn.lift(func.bind(@))

  check_deployer_config = ->
    deferred = W.defer()

    if @deployer
      configure_deployer.call(@, deferred)
    else
      deferred.resolve()

    return deferred.promise

  configure_deployer = (deferred) ->
    if not @deployer then return deferred.resolve()
    if not @config then return create_conf_with_deployer.call(@, deferred)
    if not contains_deployer(@) then return add_deployer_to_conf.call(@, deferred)
    deferred.resolve()

  contains_deployer = (t) ->
    Object.keys(t.config).indexOf(t.deployer) > -1

  create_conf_with_deployer = (deferred) ->
    nodefn.call(prompt.bind(@))
      .otherwise((err) -> deferred.reject(err))
      .then (res) =>
        @config = {}
        @config[@deployer] = res
        shipfile.create(@path)
        shipfile.update(@path, @config)
        deferred.resolve()

  add_deployer_to_conf = (deferred) ->
    nodefn.call(prompt.bind(@))
      .otherwise((err) -> deferred.reject(err))
      .then (res) =>
        @config[@deployer] = res
        shipfile.update(@path, @config)
        deferred.resolve()

  set_deployer_config = ->
    deferred = W.defer()

    config_fn = (d, cb) -> d.configure(@config, cb)

    nodefn.call(async.map, @deployers, config_fn.bind(@))
      .otherwise(deferred.reject)
      .then => deferred.resolve(@deployers)

    return deferred.promise
  
  deploy_async = (deployers) ->
    deferred = W.defer()

    deployfn = (d, cb) ->
      if process.env.NODE_ENV == 'test' then d.mock_deploy(cb) else d.deploy(cb)

    async.map deployers, deployfn, (err, res) ->
      if err then deferred.reject(err)
      deferred.resolve(res)

    return deferred.promise

module.exports = DefaultCommand
