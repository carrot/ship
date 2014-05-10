s3sync = require 's3-sync'
AWS = require 'aws-sdk'
W = require 'when'
nodefn = require 'when/node/function'

Deployer = require '../../deployer'

class S3 extends Deployer
  ###*
   * Error strings
   * @type {Object<string, string>}
   * @todo Refactor into real exception types
   * @const
  ###
  _errors:
      ACCESS_DENIED: 'Access Denied: Either your credentials are incorrect, or your bucket name is already taken. Please verify your credentials and/or specify a different bucket name.'
      PERMANENT_REDIRECT: 'Permanent Redirect: This probably means you have set an incorrect region. Make sure your bucket\'s region matches what you set in the configuration.'

  constructor: ->
    super()
    @configSchema.schema.secretKey =
      type: 'string'
      required: true
    @configSchema.schema.accessKey =
      type: 'string'
      required: true
    @configSchema.schema.bucket =
      type: 'string'
      required: true
      description: 'Must be unique across all existing buckets in S3. Will be created if it doesn\'t exist.'

  deploy: (config) ->
    super(config)
    deferred = W.defer()
    @client = new AWS.S3(
      accessKeyId: @_config.accessKey
      secretAccessKey: @_config.secretKey
    )
    @checkConfig().then( =>
      uploader = s3sync(
        key: @_config.accessKey
        secret: @_config.secretKey
        bucket: @_config.bucket
      ).on('data', (file) ->
        console.log "#{file.fullPath} -> #{file.url}"
      ).on('error', (err) ->
        deferred.reject(err)
      )
      @getFileList().pipe uploader
    )
    return deferred.promise

  checkConfig: ->
    deferred = W.defer()
    @client.getBucketWebsite Bucket: @_config.bucket, (err, data) =>
      if not err then return deferred.resolve()
      switch err.code
        when 'NoSuchBucket'
          @createBucket()
            .then(@createSiteConfig())
            .done(deferred.resolve, deferred.reject)
        when 'NoSuchWebsiteConfiguration'
          @createSiteConfig
            .done(deferred.resolve, deferred.reject)
        when 'AccessDenied'
          deferred.reject(@_errors.ACCESS_DENIED)
        when 'PermanentRedirect'
          deferred.reject(@_errors.PERMANENT_REDIRECT)
        else
          deferred.reject(err)
    return deferred.promise

  createBucket: ->
    console.log "Creating bucket '#{@_config.bucket}'"
    nodefn.call(@client.createBucket, Bucket: @_config.bucket)

  createSiteConfig: ->
    console.log 'No static website configuration detected. Configuring now...'
    nodefn.call(
      @client.putBucketWebsite
      Bucket: @_config.bucket,
      WebsiteConfiguration:
        IndexDocument:
          Suffix: 'index.html'
    )

module.exports = S3
