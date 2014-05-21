s3sync = require 's3-sync'
AWS = require 'aws-sdk'
W = require 'when'
nodefn = require 'when/node/function'
_ = require 'lodash'

Deployer = require '../../deployer'

class S3 extends Deployer
  ###*
   * Error strings
   * @type {Object<string, string>}
   * @todo Refactor into real exception types
   * @const
  ###
  _errors:
    ACCESS_DENIED: 'Access Denied: Your credentials are probably incorrect'

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
      description: 'Must be unique across all existing buckets in S3.'
    @configSchema.schema.delete =
      type: 'boolean'
      required: true
      default: false
      description: 'Rather than deploying, delete the bucket.'

  deploy: (config) =>
    super(config)
    @client = new AWS.S3(
      accessKeyId: @_config.accessKey
      secretAccessKey: @_config.secretKey
    )
    if @_config.delete
      return @destroy()
    @checkConfig().then(@listObjects).then((objects) =>
      # filter out the files that we want to deploy/keep
      W.promise((resolve, reject) =>
        @getFileList((err, res) ->
          if err
            reject err
          else
            filesToDeploy = _.pluck res.files, 'path'
            resolve _.without objects, filesToDeploy...
        )
      )
    ).then(@deleteObjects).then( =>
      W.promise((resolve, reject) =>
        uploader = s3sync(
          key: @_config.accessKey
          secret: @_config.secretKey
          bucket: @_config.bucket
        ).on('data', (file) ->
          console.log "#{file.fullPath} -> #{file.url}"
        ).on('error', (err) ->
          reject(err)
        ).on('close', ->
          resolve()
        )
        @getFileList().pipe uploader
      ).then(@getBucketURL).then((url) ->
        console.log "Your site is live at: #{url}"
      )
    )

  ###*
   * Delete a list of objects from the bucket
   * @param {Array} objects An array of filepaths to remove
  ###
  deleteObjects: (objects) =>
    W.promise((resolve, reject) =>
      if objects.length is 0 then resolve()
      @client.deleteObjects
        Bucket: @_config.bucket
        Delete:
          Objects: objects.map((i) -> { Key: i })
        (err, data) ->
          if err
            reject err
          else
            resolve()
    )

  ###*
   * Delete the bucket
   * @param {Array} objects An array of filepaths to remove
  ###
  destroy: =>
    @listObjects().then(@deleteObjects).then( =>
      W.promise (resolve, reject) =>
        @client.deleteBucket Bucket: @_config.bucket, resolve
    )

  ###*
   * get the URL of the website on the bucket
  ###
  getBucketURL: =>
    W.promise((resolve, reject) =>
      @client.getBucketLocation(Bucket: @_config.bucket, (err, data) =>
        if err then reject err
        # workaround for github.com/aws/aws-sdk-js/issues/276
        data.LocationConstraint ?= 'us-east-1'

        bucket = @_config.bucket
        location = data.LocationConstraint
        resolve(
          "http://#{bucket}.s3-website-#{location}.amazonaws.com"
        )
      )
    )

  ###*
   * List all the objects in the bucket
  ###
  listObjects: =>
    W.promise((resolve, reject) =>
      @client.listObjects Bucket: @_config.bucket, (err, data) ->
        if err
          reject err
        else
          # pull the objects out into an array of filepaths
          resolve _.pluck data.Contents, 'Key'
    )

  checkConfig: ->
    deferred = W.defer()
    @client.getBucketWebsite Bucket: @_config.bucket, (err, data) =>
      if not err then return deferred.resolve()
      switch err.code
        when 'NoSuchBucket'
          @createBucket()
            .then(@createSiteConfig)
            .done(deferred.resolve, deferred.reject)
        when 'NoSuchWebsiteConfiguration'
          @createSiteConfig()
            .done(deferred.resolve, deferred.reject)
        when 'AccessDenied'
          deferred.reject(@_errors.ACCESS_DENIED)
        else
          deferred.reject err
    return deferred.promise

  createBucket: ->
    console.log "Creating bucket '#{@_config.bucket}'"
    W.promise((resolve, reject) =>
      @client.createBucket(
        Bucket: @_config.bucket
        (err, data) ->
          if err then reject err else resolve()
      )
    )

  createSiteConfig: =>
    console.log 'No static website configuration detected. Configuring now...'
    W.promise((resolve, reject) =>
      @client.putBucketWebsite(
        Bucket: @_config.bucket
        WebsiteConfiguration:
          IndexDocument:
            Suffix: 'index.html'
        (err, data) ->
          if err then reject err else resolve()
      )
    )

module.exports = S3
