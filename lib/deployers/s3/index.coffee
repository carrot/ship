require 'colors'
path = require 'path'
fs = require 'fs'
W = require 'when'
AWS = require 'aws-sdk'
_ = require 'underscore'
async = require 'async'
mime = require 'mime'
readdirp = require 'readdirp'
Deployer = require '../deployer'

class S3 extends Deployer

  constructor: (@path) ->
    @name = 'Amazon S3'
    @config =
      bucket: null
      region: null
      secret_key: null
      access_key: null

    @errors =
      access_denied: "Access Denied: Either your credentials are incorrect, or your bucket name is already taken. Please verify your credentials and/or specify a different bucket name."
      permanent_redirect: "Permanent Redirect: This probably means you have set an incorrect region. Make sure you're bucket's region matches what you set in the configuration."

  configure: (config) ->
    @config = config

    AWS.config = new AWS.Config(secretAccessKey: @config.secret_key, accessKeyId: @config.access_key)
    AWS.config.bucket = @config.bucket || process.cwd().split(path.sep).reverse()[0]
    AWS.config.region = @config.region || 'us-east-1'
    @client = new AWS.S3

  deploy: (cb) ->
    console.log "deploying #{@path} to S3"

    create_bucket.call(@)
    .then(upload_files.bind(@))
    .otherwise((err) -> console.error(err))
    .ensure(cb)

  create_bucket = ->
    deferred = W.defer()

    @client.getBucketWebsite { Bucket: @config.bucket }, (err, data) =>
      if not err then return deferred.resolve()

      switch err.code
        when 'NoSuchBucket'
          create_bucket.call(@)
            .then(create_site_config.bind(@))
            .otherwise(deferred.reject)
            .ensure(deferred.resolve)
        when 'NoSuchWebsiteConfiguration'
          create_site_config.call(@)
            .otherwise(deferred.reject)
            .ensure(deferred.resolve)
        when 'AccessDenied'
          deferred.reject(@errors.access_denied)
        when 'PermanentRedirect'
          deferred.reject(@errors.permanent_redirect)
        else
          deferred.reject(err)

    return deferred.promise

  upload_files = ->
    deferred = W.defer()

    readdirp { root: @public }, (err, res) ->
      files = _.pluck(res.files, 'path')

      async.map files, put_file, (err) ->
        if err then return deferred.reject(err)
        console.log "success! your site has been deployed to: http://#{AWS.config.bucket}.s3-website-#{AWS.config.region}.amazonaws.com".green
        deferred.resolve()

    return deferred.promise

  # 
  # @api private
  # 

  create_bucket = ->
    deferred = W.defer()

    process.stdout.write "Creating bucket '#{@config.bucket}'..."
    @client.createBucket { Bucket: @config.bucket }, (err, data) ->
      if err then return deferred.reject(err)
      console.log 'done!'.green
      deferred.resolve()

    return deferred.promise

  create_site_config = ->
    deferred = W.defer()

    process.stdout.write 'No static website configuration detected. Configuring now...'.grey

    site_config =
      Bucket: @config.bucket,
      WebsiteConfiguration:
        IndexDocument:
          Suffix: 'index.html'

    @client.putBucketWebsite site_config, (err, data) ->
      if err then return deferred.reject(err)
      console.log 'done!'.green
      deferred.resolve()

    return deferred.promise

  put_file = (fpath, cb) ->
    contents = fs.readFileSync(path.join(@public, fpath))

    @client.putObject
      Bucket: @config.bucket
      Key: fpath
      Body: contents
      ACL: 'public-read'
      ContentType: mime.lookup(fpath)
    , (err, data) ->
      if err then return cb(err)
      console.log "uploaded #{fpath}".green
      cb()

    return deferred.promise
