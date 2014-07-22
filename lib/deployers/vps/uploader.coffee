W        = require 'when'
nodefn   = require 'when/node'
path     = require 'path'
_        = require 'lodash'
readdirp = require 'readdirp'

class SFTPUploader

  constructor: (@sftp) ->

  # upload a given local directory to a remote path
  # returns a promise
  upload_project: (local, remote) ->

    @local = local
    @remote = remote

    create_folder_structure.call(@)
      .with(@)
      .then(upload_files)
      .then(symlink_current)

  #
  # @api private
  #

  create_folder_structure = ->
    # create release folder
    @release = path.join(@remote, 'releases', (new Date).getTime())
    @sftp.mkdir(@release)

    # mirror project folder structure
    nodefn.call(readdirp, { root: @local }).then ->
      folders = _.pluck(res.directories, 'path').map (f) ->
        path.join(@release, f)
      files = _.pluck(res.files, 'path')

      W.map(folders, @sftp.mkdir.bind(@sftp))
        .yield(_.pluck(res.files, 'path'))

  upload_files = (files) ->
    W.map(files, (f, cb) => @sftp.fastPut(f, path.join(@release, f), cb))

  symlink_current = ->
    @sftp.symlink(@release, path.join(@remote, 'current'))
