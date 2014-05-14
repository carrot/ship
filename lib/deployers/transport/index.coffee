readdirp = require 'readdirp'
_ = require 'lodash'
W = require 'when'
nodefn = require 'when/node'
path = require 'path'

Deployer = require '../../deployer'

class FTP extends Deployer

  deploy: (config) ->
    super(config)
    @checkCredentials(config)
      .then( => @clearFilesFromTarget())
      .then( => @uploadFiles(config.sourceDir))

  clearFilesFromTarget: ->
    console.log 'removing existing files from target dir'
    @removeRecursive()

  ###*
   * Recursively remove everything inside of a given dir.
   * @param {String} dir
   * @return {Promise}
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
