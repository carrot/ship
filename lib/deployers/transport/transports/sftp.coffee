Connection = require 'ssh2'
constants = process.binding 'constants'
fs = require 'fs'
path = require 'path'
Transport = require '../transport'

isDirectory = (attrs) ->
  (attrs.mode & constants.S_IFMT) is constants.S_IFDIR

class SFTP extends Transport
  options:
    host:
      required: true
      description: 'hostname'
    port:
      description: 'port (default: 22)'
    privateKey:
      description: 'path to private key'
    username:
      description: 'username (default: $USER)'
    agent:
      description: 'ssh agent socket (default: $SSH_AUTH_SOCK)'

  constructor: (options) ->
    @host = options.host
    @port = options.port or 22
    @username = options.username or process.env['USER']
    @agent = options.agent or process.env['SSH_AUTH_SOCK']
    @privateKey = fs.readFileSync(options.privateKey).toString()  if options.privateKey
    return

  setup: (cb) ->
    onSftpEnd = ->
      self.logger.error 'sftp connection closed unexpectedly'
      return
    onConnectionEnd = ->
      self.logger.error 'ssh connection closed unexpectedly'
      return
    self = this
    self.connection = new Connection()
    self.connection.on 'ready', ->
      self.logger.debug 'ssh ready'
      self.connection.sftp (error, sftp) ->
        self.sftp = sftp
        self.logger.debug 'sftp open'
        self.sftp.on 'error', (error) ->
          self.logger.error 'sftp error', error
          return

        self.sftp.on 'end', onSftpEnd
        cb error
        return

      return

    self.connection.on 'end', onConnectionEnd
    self.connection.on 'error', cb
    self.connection.connect
      host: self.host
      port: self.port
      username: self.username
      privateKey: self.privateKey
      agent: self.agent


    # references so we can remove the event listeners later
    self.__onSftpEnd = onSftpEnd
    self.__onConnectionEnd = onConnectionEnd
    return

  cleanup: (cb) ->
    @sftp.removeListener 'end', @__onSftpEnd
    @connection.removeListener 'end', @__onConnectionEnd

    #this.connection.on('end', cb)
    @sftp.end()
    @connection.end()
    cb()
    return

  listDirectory: (dirname, cb) ->
    self = this
    self.sftp.opendir dirname, (error, handle) ->
      if error?
        cb error
        return
      self.sftp.readdir handle, (error, list) ->
        file = undefined
        rv = []
        unless error?
          i = 0
          while i < list.length
            file = list[i]
            continue  if file.filename is '.' or file.filename is '..'
            if isDirectory(file.attrs)
              rv.push file.filename + '/'
            else
              rv.push file.filename
            i++
        cb error, rv
        return
      return
    return

  makeDirectory: (dirname, cb) ->
    @sftp.mkdir dirname, cb
    return

  deleteDirectory: (dirname, cb) ->
    @sftp.rmdir dirname, cb
    return

  createReadStream: (filename) ->
    @sftp.createReadStream filename

  putFile: (filename, size, stream, cb) ->
    writeStream = @sftp.createWriteStream(filename)
    writeStream.on 'close', cb
    writeStream.on 'error', cb
    stream.pipe writeStream
    return

  deleteFile: (filename, cb) ->
    @sftp.unlink filename, cb
    return

module.exports = SFTPTransport
