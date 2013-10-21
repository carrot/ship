require 'coffee-script'
Deployer = require '../deployer'
W = require 'when'
fs = require 'fs'
path = require 'path'

class VPS extends Deployer

  constructor: (@path) ->
    @name = 'VPS'
    @config =
      user: null
      host: null
      local_target: null
      remote_target: null

    # optional config values:
    # - key (path to .pem)
    # - port (port to connect through)
    # - before (path to before script)
    # - after (path to after script)

  deploy: (cb) ->
    console.log "deploying #{@path} to VPS"

    run_before_script.call(@)
    .then(deploy_files.bind(@))
    .then(run_after_script.bind(@))
    .otherwise((err) -> console.error(err))
    .ensure(cb)

  run_before_script = ->
    deferred = W.defer()
    if not @config.before then return deferred.resolve()
    run_script.call(@, 'before', deferred)
    return deferred.promise

  deploy_files = ->
    # deploy files here through ssh
  
  run_after_script = ->
    deferred = W.defer()
    if not @config.after then return deferred.resolve()
    run_script.call(@, 'after', deferred)
    return deferred.promise

  # 
  # @api private
  # 
  
  run_script = (type, deferred) ->
    # make correct variable available here
    s = require(path.normalize(@config[type]))

    # make sure to record output
    W.all([(-> execute_local(s.local)), (-> execute_remote(s.remote))])
      .otherwise(deferred.reject)
      .then (res) ->
        console.log "local output: #{res[0]}"
        console.log "remote output: #{res[1]}"
        deferred.resolve()

  execute_local = (script) ->
    deferred = W.defer()
    if not script then deferred.resolve()
    console.log "executing locally: "
    console.log script
    return deferred.promise

  execute_remote = (script) ->
    deferred = W.defer()
    if not script then deferred.resolve()
    console.log "executing on remote: "
    console.log script
    return deferred.promise

module.exports = VPS
