require 'colors'

path = require 'path'
fs = require 'fs'
W = require 'when'
nodefn = require 'when/node/function'
Deployer = require '../deployer'
nodemailer = require 'nodemailer'
zip = require 'node-zip'
targz = require 'tar.gz'

class Email extends Deployer
  console.log 'email deployer starting'
  
  constructor: (@path) ->
    super
    @name = 'Email'
    @conf =
      target: null
      service: null
      username: null
      password: null
      compression_method: ''
      recipient: null
      subject: ''
      message: ''

    @errors =
      access_denied: "Access Denied: Your credentials are incorrect. Please verify your credentials."
      missing_conf: "You're missing #{ @conf.error }, please reconfure your ship.conf"

  deploy: (cb) ->
    console.log "deploying"
    compression.call(@)
    .then(envolope.bind())
    .otherwise((err) -> console.error(err))
    .ensure(cb)
  
  configure: (data, cb) ->
    @conf = data.email

    @payload1 = if @conf.target then path.join(@path, @conf.target) else path
    @ignores = ['ship*.conf']
    if data.ignore then @ignores = @ignores.concat(data.ignore)

  compression: ->
    console.log 'compressing'
    compress = @conf.compression_method

    files = _.pluck(remove_ignores(@conf.target, @ignores), 'path')

    if compress.toLowerCase() is "zip" then zipFile(@conf.target, cb())
    else tarballFile(@conf.target, cb())

    console.log 'compressing complete'


  #
  # @api private
  #

  config_check = ->
    deferred = W.defer()
    console.log 'config check'


  config_build = ->
    console.log 'build config'

  envolope = (fpath) ->
    contents =
      to: "<#{ @conf.recipient }>"
      from: "<#{ @conf.username }>"
      subject: "#{ @conf.subject }"
      text: "#{ @conf.message }"
      attachments: [
        fileName: fpath
      ]

    postMaster = nodemailer.createTransport "SMTP",
      service: "#{ @conf.server }"
      auth:
        user: @conf.username
        pass: @conf.password

    postMaster.sendMail envolope, (error, responseStatus) ->
      unless error
        console.log "#{responseStatus.message}\n#{responseStatus.messageID}".red
        return deferred.reject(error)

    console.log 'envolope built'

  tarballFile = (file) ->
    compress = new targz().compress "#{ file }", "../#{ file }", (error) ->
      if error then deferred.reject(error)

  zipFile = (file) ->
    # zip compression
    zip.file file
    data = zip.generate
      base64: false
      compression: 'DEFLATE'

    fs.writeFileSync "../#{file}.zip", data, 'binary'
    
    compressed_payload = "#{file}.zip"

  remove_ignores = (files, ignores) ->
    mask = []
    mask.push _(ignores).map((i) -> minimatch(f.path, i)).contains(true) for f in files
    files.filter((m,i) -> not mask[i])

module.exports = Email
