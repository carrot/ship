path      = require 'path'
fs        = require 'fs'
W         = require 'when'
nodefn    = require 'when/node/function'
AWS       = require 'aws-sdk'
_         = require 'lodash'
mime      = require 'mime'
readdirp  = require 'readdirp'
minimatch = require 'minimatch'

module.exports = (root, config) ->
  d = W.defer()

  config.region ?= 'us-east-1'
  config.bucket ?= root.split(path.sep).reverse()[0]
  config.ignore = _.compact(['ship*.conf'].concat(config.ignore))

  client = create_client(config)

  d.notify("Deploying #{root} to Amazon S3")
  ctx = { d: d, client: client, config: config, root: root }

  check_config.call(ctx)
    .then(upload_files.bind(ctx))
    .done ->
      d.resolve
        deployer: 's3'
        url: "http://#{config.bucket}.s3-website-#{config.region}.amazonaws.com"
        destroy: destroy.bind(ctx)
    , d.reject

  return d.promise

module.exports.config =
  required: ['secret_key', 'access_key']
  optional: ['region', 'bucket', 'ignore']

errors =
  access_denied: "Access Denied: Either your credentials are incorrect, or
  your bucket name is already taken. Please verify your credentials and/or
  specify a different bucket name."
  permanent_redirect: "Permanent Redirect: This probably means you have set
  an incorrect region. Make sure you're bucket's region matches what you set
  in the configuration."

create_client = (config) ->
  AWS.config.update
    secretAccessKey: config.secret_key
    accessKeyId: config.access_key
    bucket: config.bucket
    region: config.region

  new AWS.S3

check_config = ->
  nodefn.call(@client.getBucketWebsite.bind(@client), Bucket: @config.bucket)
  .catch (err) =>
    switch err.code
      when 'NoSuchBucket'
        return create_bucket.call(@)
        .then(create_site_config.bind(@))
      when 'NoSuchWebsiteConfiguration'
        return create_site_config.call(@)
      when 'AccessDenied'
        throw errors.access_denied
      when 'PermanentRedirect'
        throw errors.permanent_redirect
      else
        throw err

create_bucket = ->
  @d.notify("Creating bucket '#{@config.bucket}'...")

  nodefn.call(@client.createBucket.bind(@client), Bucket: @config.bucket)
  .tap(=> @d.notify 'Bucket created')

create_site_config = ->
  @d.notify 'Setting up static website configuration...'

  site_config =
    Bucket: @config.bucket,
    WebsiteConfiguration:
      IndexDocument:
        Suffix: 'index.html'

  nodefn.call(@client.putBucketWebsite.bind(@client), site_config)
  .tap(=> @d.notify 'Static website configuration set up')

upload_files = ->
  nodefn.call(readdirp, { root: @root })
  .then (res) =>
    files = _.pluck(remove_ignores(res.files, @config.ignore), 'path')
    W.map(files, put_file.bind(@))

put_file = (fpath, cb) ->
  nodefn.call(fs.readFile, path.join(@root, fpath))
  .then (contents) => nodefn.call @client.putObject.bind(@client),
    Bucket: @config.bucket
    Key: fpath
    Body: contents
    ACL: 'public-read'
    ContentType: mime.lookup(fpath)
  .tap => @d.notify "uploaded #{fpath}"

remove_ignores = (files, ignores) ->
  mask = []
  for f in files
    mask.push _(ignores).map((i) -> minimatch(f.path, i)).contains(true)
  files.filter((m,i) -> not mask[i])

destroy = ->
  nodefn.call(@client.listObjects.bind(@client), { Bucket: @config.bucket })
    .then (data) =>
      nodefn.call @client.deleteObjects.bind(@client),
        Bucket: @config.bucket
        Delete: { Objects: data.Contents.map((i) -> { Key: i.Key }) }
    .then =>
      nodefn.call(@client.deleteBucket.bind(@client), Bucket: @config.bucket )
