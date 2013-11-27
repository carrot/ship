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
minimatch = require 'minimatch'

class S3 extends Deployer

  constructor: (@path) ->
    super
    @name = 'Amazon S3'
    @config =
      secret_key: null
      access_key: null

      # optional config values
      # - region: defaults to 'us-east-1'
      # - bucket: defaults to the current folder name. the bucket name you choose must be unique across all existing bucket names in Amazon S3

    @errors =
      access_denied: "Access Denied: Either your credentials are incorrect, or your bucket name is already taken. Please verify your credentials and/or specify a different bucket name."
      permanent_redirect: "Permanent Redirect: This probably means you have set an incorrect region. Make sure you're bucket's region matches what you set in the configuration."

  configure: (data, cb) ->
    @config = data.s3

    # defaults
    @config.bucket ||= process.cwd().split(path.sep).reverse()[0]
    @config.region ||= 'us-east-1'

    AWS.config.update
      secretAccessKey: @config.secret_key
      accessKeyId: @config.access_key
      bucket: @config.bucket
      region: @config.region

    @client = new AWS.S3
    @public = path.join(@path, data.target || '')
    @ignores = ['ship*.conf'].concat(data.ignore)

    cb()

  deploy: (cb) ->
    @debug.log "deploying #{@path} to #{@name}"

    check_config.call(@)
    .then(upload_files.bind(@))
    .otherwise((err) -> cb(err))
    .then((res) -> cb(null, res))

  destroy: (cb) ->
    @client.listObjects { Bucket: @config.bucket }, (err, data) =>
      if err then return console.error(err)
      @client.deleteObjects
        Bucket: @config.bucket
        Delete:
          Objects: data.Contents.map((i) -> { Key: i.Key })
      , (err, data) =>
        if err then return console.error(err)
        @client.deleteBucket { Bucket: @config.bucket }, cb

  # 
  # @api private
  # 
  
  check_config = ->
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

    readdirp { root: @public }, (err, res) =>

      # ship ignore support
      for file, i in res.files
        if file
          ignored = false
          for ignore_path in @ignores
            if minimatch(file.path, ignore_path) then ignored = true
        if ignored then res.files.splice(i, 1)

      files = _.pluck(res.files, 'path')

      async.map files, put_file.bind(@), (err) =>
        if err then return deferred.reject(err)
        post_deply_message = "S3: ".bold + "Your site is live at: http://#{@config.bucket}.s3-website-#{@config.region}.amazonaws.com"
        deferred.resolve(post_deply_message)

    return deferred.promise

  create_bucket = ->
    deferred = W.defer()

    @debug.write "Creating bucket '#{@config.bucket}'..."
    @client.createBucket { Bucket: @config.bucket }, (err, data) =>
      if err then return deferred.reject(err)
      @debug.log 'done!'
      deferred.resolve()

    return deferred.promise

  create_site_config = ->
    deferred = W.defer()

    @debug.write 'No static website configuration detected. Configuring now...'

    site_config =
      Bucket: @config.bucket,
      WebsiteConfiguration:
        IndexDocument:
          Suffix: 'index.html'

    @client.putBucketWebsite site_config, (err, data) =>
      if err then return deferred.reject(err)
      @debug.log 'done!'
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
    , (err, data) =>
      if err then return cb(err)
      @debug.log "uploaded #{fpath}"
      cb()

module.exports = S3
