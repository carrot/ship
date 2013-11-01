Deployer = require '../deployer'
W = require 'when'
fn = require 'when/function'
dbox = require 'dbox'
open = require 'open'
path = require 'path'
fs = require 'fs'
readdirp = require 'readdirp'
connect = require 'connect'
async = require 'async'
shipfile = require('../../shipfile')
_ = require 'underscore'

class Dropbox extends Deployer

  constructor: (@path) ->
    super
    @name = 'Dropbox'
    @config =
      app_key: null
      app_secret: null

      # optional global config
      # - access_token: oauth_token handed back from dropbox auth

  configure: (data, cb) ->
    @config = data.dropbox

    # defaults
    @config.target ||= process.cwd()

    @public = path.join(@path, @config.target)
    @app = dbox.app(app_key: @config.app_key, app_secret: @config.app_secret)

    if !@config.access_token
      @debug.log ""
      get_request_token.call(@)
      .then(open_browser.bind(@))
      .then(create_callback_server.bind(@))
      .then(get_access_token.bind(@))
      .then(sync(update_shipfile, @))
      .otherwise(console.error)
      .then(cb)
    else
      cb()

    

  deploy: (cb) ->
    @debug.log "deploying #{@path} to Dropbox"

    fn.call(upload_files.bind(@))
    .otherwise((err) -> cb(err))
    .then((res) -> cb(null, res))

  destroy: (cb) ->
    @debug.log "removing access token from ship.conf..."
    
    conf = {}
    conf.dropbox = @config
    delete conf.dropbox['access_token']
    shipfile.update(@path, conf)

    @debug.log "removing test files from Dropbox..."
    @client.rm(@config.target, cb)


  # 
  # @api private
  # 

  get_request_token = ->
    deferred = W.defer()
    @debug.log "getting request token..."

    @app.requesttoken (status, request_token) ->
      if status != 200 then return deferred.reject(status)
      deferred.resolve(request_token)

    return deferred.promise

  open_browser = (token_obj, cb) ->
    deferred = W.defer()
    @debug.log "opening browser..."

    open "#{token_obj.authorize_url}&oauth_callback=http://localhost:9898/"
    deferred.resolve(token_obj)

    return deferred.promise

  create_callback_server = (request_token) ->
    deferred = W.defer()  
    @debug.log "creating callback server..."
    
    connect.createServer((req, res) ->
      res.end "You may close this window"
      deferred.resolve(request_token)
    ).listen 9898

    return deferred.promise

  get_access_token = (request_token) ->
    deferred = W.defer()
    @debug.log "getting access token..."
    
    @app.accesstoken request_token, (status, access_token) =>
      if status != 200 then return deferred.reject(status)
      @config.access_token = access_token
      deferred.resolve()

    return deferred.promise

  update_shipfile = ->
    @debug.log "updating shipfile with access token..."
    conf = {}
    conf.dropbox = @config
    shipfile.update(@path, conf)

  sync = (func, ctx) ->
    fn.lift(func.bind(ctx))

  upload_files = ->
    deferred = W.defer()
    @debug.log "uploading files to Dropbox..."

    readdirp { root: @path }, (err, res) =>
      files = _.pluck(res.files, 'path')
      @client = @app.client(@config.access_token)
      async.map files, put_file.bind(@), (err) =>
        if err then return deferred.reject(err)
        post_deply_message = "Dropbox: ".bold + "Your files have been deployed to Dropbox"
        deferred.resolve(post_deply_message)

    return deferred.promise  


  put_file = (fpath, cb) ->
    target = path.join(@config.target, 'index.html')
    contents = fs.readFileSync(path.join(@path, 'index.html'))
    
    @client.put target, contents, (status, reply) =>
      if status != 200 then return cb(reply)
      @debug.log "uploaded #{fpath}"
      cb()

module.exports = Dropbox
