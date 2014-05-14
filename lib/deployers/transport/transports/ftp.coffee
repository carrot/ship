FTPClient = require 'jsftp'
W = require 'when'
nodefn = require 'when/node'
_ = require 'lodash'

Transport = require '../transport'

class Ftp extends Transport
  constructor: ->
    super()
    @client = new FTPClient()
    @configSchema.schema.host =
      type: 'string'
      required: true
      default: 'localhost'
    @configSchema.schema.username =
      type: 'string'
      required: true
      default: 'anonymous'
    @configSchema.schema.password =
      type: 'string'
      required: true
      default: 'anonymous'
    @configSchema.schema.port =
      type: 'integer'
      required: true
      default: 21

  config: (config) ->
    super(config).then( =>
      W.promise((resolve, reject, notify) =>
        notify 'checking credentials'
        @client.connect
          host: @_config.host
          user: @_config.username
          pass: @_config.password
          port: @_config.port

        @client.on 'ready', =>
          @client.cwd @_config.path, (err) ->
            if err then return reject err
            resolve()

        @client.on 'error', (err) ->
          reject err
      )
    )

  cleanup: ->
    @client.end()
    W.resolve()

  ls: (dirname) ->
    nodefn.call(@client.ls.bind(@client), dirname)

  stat: (path) ->
    nodefn.call(@client.ls.bind(@client), path)

  mkdir: (dirname) ->
    nodefn.call(@client.mkdir.bind(@client), dirname, true)

  createReadStream: (filename) ->
    nodefn.call(@client.getGetSocket.bind(@client), filename)

  createWriteStream: (filename) ->
    nodefn.call(@client.getPutStream.bind(@client), filename)

  rm: (path) ->
    nodefn.call(@client.delete.bind(@client), path)

  mv: (oldPath, newPath) ->
    nodefn.call(@client.rename.bind(@client), oldPath, newPath)

module.exports = Ftp
