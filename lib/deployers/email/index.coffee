require 'colors'
Deployer = require '../deployer'
path = require 'path'
fs = require 'fs'
shell = require 'shelljs/global'
readdirp = require 'readdirp'
W = require 'when'
fn = require 'when/function'
nodemailer = require 'nodemailer'
zip = require 'node-zip'
targz = require 'tar.gz'

class Email extends Deployer
  console.log 'email deployer starting'
  
  constructor: ->
    super
    @name = 'Email'
    @conf =
      target: null
      ignore: null
      service: null
      username: null
      password: null
      compression_method: null
      recipient: null
      subject: ''
      message: ''

    @errors =
      access_denied: "Access Denied: Your credentials are incorrect. Please verify your credentials."
      missing_conf: "You're missing #{ @conf.error }, please reconfure your ship.conf"

  conf: (data, cb) ->
    @conf = data.email

    @payload1 = if @conf.target then path.join(@path, @conf.target) else path
    @ignores = ['ship*.conf']
    if data.ignore then @ignores = @ignores.concat(data.ignore)


  deploy: (cb) ->
    console.log 'deploying'

    envolope =
      from: "<#{ @conf.username }>"
      to: "<#{ @conf.recipient }>"
      subject: "#{ @conf.subject }"
      text: "#{ @conf.message }"
      attachments: [
      #TODO: add path to filename after compression 
        fileName: null
      ]
    

    postMaster = nodemailer.createTransport "SMTP",
      service: "#{@conf.server}"
      auth:
        user: @conf.username
        pass: @conf.password

    postMaster.sendMail envolope, (error, responseStatus) ->
      unless error
        console.log "#{responseStatus.message}\n#{responseStatus.messageID}"
      else
        console.log "Email sent!".green

    cb()

  compression: (cb) ->
    compress = @conf.compression_method

    files = _.pluck(remove_ignores(@conf.target, @ignores), 'path')

    switch compress.toLowerCase()
      when "tarball" then tarballFile(@conf.target, cb)
      when "zip" then zipFile(@conf.target, cb)

  #
  # @api private
  #

  tarballFile = (path, cb) ->
    gzip = zlib.createGzip()

    compress = new targz().compress "#{ target }", "../#{ target }", (error) ->
      if error then console.log error

  zipFile = (path, cb) ->
    # zip compression
    zip.file path
    data = zip.generate
      base64: false
      compression: 'DEFLATE'

    fs.writeFileSync "../#{path}.zip", data, 'binary'
    
    compressed_payload = "#{path}.zip"

  remove_ignores = (files, ignores) ->
    mask = []
    mask.push _(ignores).map((i) -> minimatch(f.path, i)).contains(true) for f in files
    files.filter((m,i) -> not mask[i])
