require 'coffee-script'
fs = require 'fs'
path = require 'path'
Q = require 'q'
async = require 'async'
colors = require 'colors'
prompt = require 'prompt'
yaml = require 'js-yaml'
arg_parser = require './arg_parser'
Deployers = require '../deployers'

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
    Q.nfcall(config_prompt.bind(@))
      .catch((err) -> deferred.reject(err))
      .then (res) =>
        @config = {}
        @config[@deployer] = res
        create_config_file(@path)
        update_config_file(@path, @config)
        deferred.resolve()

  add_deployer_to_conf = (deferred) ->
    Q.nfcall(config_prompt.bind(@))
      .catch((err) -> deferred.reject(err))
      .then (res) =>
        @config[@deployer] = res
        update_config_file(@path, @config)
        deferred.resolve()

  config_prompt = (cb) ->
    console.log "please enter the following config details for #{@deployers[0].name.bold}".green
    console.log "need help? see #{'HELP URL'}".grey

    prompt.start()
    async.mapSeries(Object.keys(@deployers[0].config), ((k,c)-> prompt.get([k],c)), cb)

  create_config_file = (p) ->
    console.log "creating conf file"
    # fs.openSync(path.join(p, 'ship.conf'), 'w')

  update_config_file = (p, new_config) ->
    shipfile = path.join(p, 'ship.conf')
    console.log "updating conf file"
    console.log yaml.safeDump(new_config)
    # fs.writeFileSync(shipfile, yaml.safeDump(new_config))

  set_deployer_config = ->
    @deployer.config = @config for deployer in @deployers
    return Q.fcall => @deployers
  
  deploy_async = (deployers) ->
    deferred = Q.defer()

    async.map deployers, ((d,c) -> d.deploy(c)), (err, res) ->
      if err then deferred.reject(err)
      deferred.resolve()

    return deferred.promise

module.exports = DefaultCommand
