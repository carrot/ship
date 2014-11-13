W            = require 'when'
fs           = require 'fs'
path         = require 'path'
SSH          = require 'ssh2'
SFTPUploader = require './uploader'

module.exports = (@root, @config) ->
  @d = W.defer()

  W().with(@)
    .then(test_connection)
    .then(run_before_script)
    .then(deploy_files)
    .then(run_after_script)
    .done((=> @d.resolve(name: 'vps')), @d.reject.bind(@d))

  return @d.promise

test_connection = ->
  deferred = W.defer()

  ssh = new SSH
  ssh.connect
    host: @config.host
    port: @config.port || 22
    username: @config.username
  ssh.on('error', deferred.reject)
  ssh.on('ready', deferred.resolve)

  return deferred.promise

run_before_script = ->
  if not @config.before then return W.resolve()
  run_script.call(@, 'before')

deploy_files = ->
  nodefn.call(ssh.sftp)
    .tap (sftp) ->
      uploader = new SFTPUploader(sftp)
      uploader.upload_project(@root, @config.target)
    .tap (sftp) -> sftp.end()

run_after_script = ->
  if not @config.after then return W.resolve()
  run_script.call(@, 'after')

#
# @api private
#

run_script = (type) ->
  s = require(path.normalize(@config[type]))

  W.all([execute_local.bind(@, s.local), execute_remote.bind(@, s.remote)])
    .then (res) ->
      @d.notify("local output: #{res[0]}")
      @d.notify("remote output: #{res[1]}")

execute_local = (script) ->
  if not script then return W.resolve()
  @d.notify("executing locally: ")
  @d.notify(script)
  W.resolve()

execute_remote = (script) ->
  if not script then return W.resolve()
  @d.notify("executing on remote: ")
  @d.notify(script)
  W.resolve()

module.exports = VPS
