W = require 'when'
path = require 'path'
_ = require 'underscore'
readdirp = require 'readdirp'
async = require 'async'

class SFTPUploader

  constructor: (@sftp) ->

  # upload a given local directory to a remote path
  # returns a promise
  upload_project: (local, remote) ->

    @local = local
    @remote = remote

    create_folder_structure.call(@)
      .then(upload_files.bind(@))
      .then(symlink_current.bind(@))
      .otherwise(deferred.reject)
      .ensure(deferred.resolve)

  # 
  # @api private
  # 

  create_folder_structure = ->
    deferred = W.defer()

    # create release folder
    @release = path.join(@remote, 'releases', (new Date).getTime())
    @sftp.mkdir(@release)

    # mirror project folder structure
    readdirp { root: @local }, (err, res) ->
      if err then return deferred.reject(err)
      folders = _.pluck(res.directories, 'path').map((f) -> path.join(@release, f))
      files = _.pluck(res.files, 'path')

      async.map folders, @sftp.mkdir, (err) ->
        if err then return deferred.reject(err)
        deferred.resolve(files)

    return deferred.promise

  upload_files = (files) ->
    deferred = W.defer()

    put_file = (f, cb) -> @sftp.fastPut(f, path.join(@release, f), cb)

    async.map files, put_file, (err) ->
      if err then return deferred.reject(err)
      deferred.resolve()

    return deferred.promise
  
  symlink_current = ->
    @sftp.symlink(@release, path.join(@remote, 'current'))
