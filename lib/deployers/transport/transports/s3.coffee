knox = require 'knox'
mime = require 'mime'
Transport = require '../transport'

class S3 extends Transport
  options:
    key:
      required: true
      description: 'S3 key'

    secret:
      required: true
      description: 'S3 secret'

    bucket:
      required: true
      description: 'S3 bucket'

    region:
      required: false
      description: 'S3 region'

    endpoint:
      required: false
      description: 'S3 endpoint'

    port:
      required: false
      description: 'S3 endpoint port'

    secure:
      required: false
      description: 'S3 https transport'

    style:
      required: false
      description: 'S3 url style'

  constructor: (options) ->
    # required config
    @key = options.key
    @secret = options.secret
    @bucket = options.bucket

    # optional config
    @endpoint = options.endpoint
    @port = options.port
    @secure = options.secure
    @style = options.style
    return

  setup: (cb) ->
    knoxopt =
      key: @key
      secret: @secret
      bucket: @bucket

    knoxopt.endpoint = @endpoint if @endpoint
    knoxopt.port = @port if @port
    knoxopt.secure = @secure if @secure
    knoxopt.style = @style if @style
    @client = knox.createClient(knoxopt)
    cb()
    return

  cleanup: (cb) ->
    cb()
    return

  listDirectory: (dirname, cb) ->
    prefix = dirname.replace(/^(.\/|\/)/g, '')
    @client.list
      prefix: prefix
    , (error, data) ->
      files = undefined
      if data?
        files = data.Contents.map((item) ->
          item.Key
        )
      cb error, files
      return

    return

  makeDirectory: (dirname, cb) ->
    cb()
    return

  deleteDirectory: (dirname, cb) ->
    cb()
    return

  getFile: (filename, cb) ->
    @client.getFile filename, cb
    return

  putFile: (filename, size, stream, cb) ->
    self = this
    headers =
      'Content-Length': size
      'Content-Type': mime.lookup(filename)

    putStream = @client.putStream(stream, filename, headers, (error, res) ->
      res.resume() # TODO: handle errors?
      cb error
      return
    )
    putStream.on 'error', (error) ->
      self.logger.error error
      return

    return

  deleteFile: (filename, cb) ->
    @client.deleteFile filename, cb
    return

module.exports = S3Transport
