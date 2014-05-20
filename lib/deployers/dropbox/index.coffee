W = require 'when'
dbox = require 'dbox'
open = require 'open'
readdirp = require 'readdirp'
_ = require 'lodash'

Deployer = require '../../deployer'

class Dropbox extends Deployer
  name: 'Dropbox'

  config:
    target: null
    app_key: null
    app_secret: null

  constructor: (@path) ->

  deploy: (cb) ->
    console.log "deploying #{@path} to Dropbox"

    upload_files.call(@)
      .done(cb, (err) -> console.error(err))

  configure: (data, cb) ->
    @config = data
    if @config.target
      @payload = path.join(@path, @config.target)
    else
      @payload = process.cwd()
    @app = dbox.app(app_key: @config.app_key, app_secret: @config.app_secret)

    # possibly use configstore to know when user has already authed so this
    # only happens once, OR write the access token to the config file
    @app.requesttoken (status, request_token) ->
      console.log request_token
      # start up a tiny server just for callback (ugh)
      # open: "https://www.dropbox.com/1/oauth/authorize?
      # oauth_token=#{request_token.oauth_token}"
      # on callback, continue
      @app.accesstoken request_token, (status, access_token) ->
        @access_token = access_token
        @client = @app.client(@access_token)

    cb()

  # this is an exact copy of the way it's done in FTP, which
  # might warrant abstracting this out to a helper
  upload_files: ->
    deferred = W.defer()
    console.log 'uploading files...'

    readdirp root: @payload, (err, res) ->
      if err then return deferred.reject(err)

      folders = _.pluck(res.directories, 'path')
      files = _.pluck(res.files, 'path')

      async.map folders, mkdir, (err) ->
        if err then return deferred.reject(err)

        async.map files, put_file, (err) ->
          if err then return deferred.reject(err)
          deferred.resolve()

  mkdir = (p, cb) ->
    @client.mkdir(path.join(@payload, p), p, cb)

  put_file = (f, cb) ->
    console.log "uploading #{f}".green
    @client.put(path.join(@payload, f), f, cb)

module.exports = Dropbox
