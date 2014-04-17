Deployer = require '../deployer'
W = require 'when'
fs = require 'fs'
path = require 'path'
SSH = require 'ssh2'
SFTPUploader = require './uploader'

class VPS extends Deployer

  constructor: (@path) ->
    @name = 'VPS'
    @config =
      host: null
      user: null
      target: null
      remote_target: null

    # optional config values:
    # - key (path to .pem)
    # - port (port to connect through)
    # - before (path to before script)
    # - after (path to after script)

  deploy: (cb) ->
    console.log "deploying #{@path} to VPS"

    test_connection.call(@)
    .then(run_before_script.bind(@))
    .then(deploy_files.bind(@))
    .then(run_after_script.bind(@))
    .otherwise((err) -> console.error(err))
    .ensure(cb)

  test_connection = ->
    deferred = W.defer()

    ssh = new SSH
    ssh.connect(host: @config.host, port: @config.port || 22, username: @config.username)
    ssh.on('error', deferred.reject)
    ssh.on('ready', deferred.resolve)

    return deferred.promise

  run_before_script = ->
    deferred = W.defer()
    if not @config.before then return deferred.resolve()
    run_script.call(@, 'before', deferred)
    return deferred.promise

  deploy_files = ->
    deferred = W.defer()

    ssh.sftp (err, sftp) =>
      if err then return deferred.reject(err)

      uploader = new SFTPUploader(sftp)

      uploader.upload_project(@public, @config.remote_target)
        .otherwise(deferred.reject)
        .ensure ->
          sftp.end()
          deferred.resolve()

    return deferred.promise

  run_after_script = ->
    deferred = W.defer()
    if not @config.after then return deferred.resolve()
    run_script.call(@, 'after', deferred)
    return deferred.promise

  #
  # @api private
  #

  run_script = (type, deferred) ->
    # make correct variables available here
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
