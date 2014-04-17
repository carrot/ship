Deployer = require '../deployer'
FTPClient = require 'ftp'
readdirp = require 'readdirp'
_ = require 'lodash'
W = require 'when'
nodefn = require 'when/node'
path = require 'path'

class FTP extends Deployer
  client: new FTPClient()

  constructor: ->
    @config.schema =
      host:
        type: 'string'
        required: true
      target:
        type: 'string'
        required: true
      username:
        type: 'string'
        required: true
      password:
        type: 'string'
        required: true
      port:
        type: 'integer'
        required: true
        default: 21

  runDeploy: (config) ->
    @checkCredentials(config)
      .then( => @clearFilesFromTarget())
      .then( => @uploadFiles(config.sourceDir))

  checkCredentials: (config) ->
    deferred = W.defer()
    console.log 'checking credentials'

    @client.connect
      host: config.host
      port: config.port
      user: config.username
      password: config.password

    @client.on 'ready', =>
      console.log 'authenticated!'
      @client.cwd config.root, (err) ->
        if err then return deferred.reject(err)
        deferred.resolve()

    @client.on 'error', (err) ->
      console.log err
      deferred.reject(err)

    return deferred.promise

  clearFilesFromTarget: ->
    console.log 'removing existing files from target dir'
    @removeRecursive()

  ###*
   * Recursively remove everything inside of a given dir.
   * @param {String} dir
   * @return {Promise} [description]
  ###
  removeRecursive: (dir = '.') ->
    nodefn.call(@client.list.bind(@client), dir).then((list) =>
      W.map list, (entry) =>
        if entry.name in ['.', '..'] then return
        name = path.join(dir, entry.name)
        console.log "removing #{name}"
        if entry.type is 'd'
          return @removeRecursive(name).then( =>
            nodefn.call(@client.rmdir.bind(@client), name)
          )
        else
          return nodefn.call(@client.delete.bind(@client), name)
    )

  ###*
   * @todo Make a way to do "nearly atomic uploads" by uploading to a tmp dir
     and then renaming to the target dir
  ###
  uploadFiles: (sourceDir) ->
    console.log 'uploading files'
    nodefn.call(readdirp, root: sourceDir).then((res) =>
      folders = _.pluck(res.directories, 'path')
      files = _.pluck(res.files, 'path')
      W.map(folders, @mkdir).then( =>
        W.map files, (file) => @putFile(file, sourceDir)
      ).then( =>
        @client.end()
      )
    )

  mkdir: (path) =>
    nodefn.call(@client.mkdir.bind(@client), path, true)

  putFile: (file, sourceDir) ->
    console.log "uploading #{file}"
    nodefn.call(@client.put.bind(@client), path.join(sourceDir, file), file)

module.exports = FTP
