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
    NO_BUCKET: 'The specified bucket doesn\'t exist'
    NO_WEBSITE: 'The specified bucket isn\'t setup for website hosting'
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

  deploy: (config) ->
    super(config)
    @client = new AWS.S3(
      accessKeyId: @_config.accessKey
      secretAccessKey: @_config.secretKey
    )
    @checkConfig().then( =>
      W.promise((resolve, reject) =>
        @client.listObjects Bucket: @_config.bucket, (err, data) =>
          if err
            reject err
          else
            # pull the objects out into an array of `{ Key: 'filepath' }`
            # formatted elements (the format that is consumed by
            # `@client.deleteObjects`)
            resolve _.pluck data.Contents, 'Key'
      )
    ).then((objects) =>
      # filter out the files that we want to deploy/keep
      W.promise((resolve, reject) =>
        @getFileList((err, res) =>
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
        ).on('done', ->
          resolve()
        )
        @getFileList().pipe uploader
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

  checkConfig: ->
    deferred = W.defer()
    @client.getBucketWebsite Bucket: @_config.bucket, (err, data) =>
      if not err then return deferred.resolve()
      switch err.code
        when 'NoSuchBucket'
          deferred.reject(@_errors.NO_BUCKET)
        when 'NoSuchWebsiteConfiguration'
          deferred.reject(@_errors.NO_WEBSITE)
        when 'AccessDenied'
          deferred.reject(@_errors.ACCESS_DENIED)
        else
          deferred.reject(err)
    return deferred.promise

module.exports = S3
