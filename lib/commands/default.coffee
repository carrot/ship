require 'coffee-script'
require 'colors'

Q = require 'q'
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
    @deployers = deployer_names.map((name) -> new Deployers[name](@path))

    check_deployer_config.call(@)
      .then(set_deployer_config.bind(@))
      .then(deploy_async)
      .catch((err) -> console.error(err))
      .done(cb)

  # 
  # @api private
  # 

  check_deployer_config = ->
    deferred = Q.defer()

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
    Q.nfcall(prompt.bind(@))
      .catch((err) -> deferred.reject(err))
      .then (res) =>
        @config = {}
        @config[@deployer] = res
        shipfile.create(@path)
        shipfile.update(@path, @config)
        deferred.resolve()

  add_deployer_to_conf = (deferred) ->
    Q.nfcall(prompt.bind(@))
      .catch((err) -> deferred.reject(err))
      .then (res) =>
        @config[@deployer] = res
        shipfile.update(@path, @config)
        deferred.resolve()

  set_deployer_config = ->
    @deployer.configure(@config) for deployer in @deployers
    return Q.fcall => @deployers
  
  deploy_async = (deployers) ->
    deferred = Q.defer()

    async.map deployers, ((d,c) -> d.deploy(c)), (err, res) ->
      if err then deferred.reject(err)
      deferred.resolve()

    return deferred.promise

module.exports = DefaultCommand
