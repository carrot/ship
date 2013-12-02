require 'colors'
Deployer = require '../deployer'
FTPClient = require 'ftp'
readdirp = require 'readdirp'
_ = require 'lodash'
W = require 'when'

class FTP extends Deployer

  constructor: (@path) ->
    super
    @name = 'FTP'
    @config =
      host: null
      root: null
      username: null
      password: null

    # optional config values
    # - port: defaults to 21

    @client = new FTPClient

  deploy: (cb) ->
    check_credentials.call(@)
    .then(upload_files.bind(@))
    .otherwise((err) -> console.error(err))
    .ensure(cb)

  check_credentials = ->
    console.log 'checking credentials...'.grey
    deferred = W.defer()

    @client.connect
      host: @config.host,
      port: @config.port || '21'
      user: @config.username,
      password: @config.password

    @client.on 'ready', ->
      console.log 'authenticated!'.grey
      @client.cwd @config.root, (err) ->
        if err then return deferred.reject(err)
        deferred.resolve()

  upload_files = ->
    console.log 'uploading files via ftp'.grey
    deferred = W.defer()

    clean_files.call(@).then ->

      readdirp { root: @public }, (err, res) ->
        if (err) then return deferred.reject(err)

        folders = _.pluck(res.directories, 'path')
        files = _.pluck(res.files, 'path')

        async.map folders, mkdir, (err) ->
          if err then return deferred.reject(err)

          async.map files, put_file, (err) ->
            if err then return deferred.reject(err)
            @client.end()
            deferred.resolve()

  clean_files = ->
    console.log 'clearing previous files'.grey
    deferred = W.defer()

    @client.list '.', (err, list) ->
      if err then return deferred.reject(err)

      async.map list, (entry, cb) ->
        if entry.name == '.' or entry.name == '..' then return cb()

        if entry.type == 'd'
          clean_files entry.name, ->
            if entry.name != '.' then return @client.rmdir(entry.name, cb)
            cb()
        else
          console.log "removing #{dir}/#{entry.name}"
          @client.delete("#{dir}/#{entry.name}", cb)

      , deferred.resolve

  mkdir = (p, cb) ->
    @client.mkdir(p, true, cb)

  put_file = (f, cb) ->
    console.log "uploading #{f}".green
    @client.put(path.join(@public, f), f, cb)

module.exports = FTP
