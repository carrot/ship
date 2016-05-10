FTPClient = require 'ftp'
readdirp  = require 'readdirp'
_         = require 'lodash'
W         = require 'when'
nodefn    = require 'when/node'

module.exports = (root, config) ->
  d = W.defer()
  @client = new FTPClient

  ctx = { d: d, client: client, root: root, config: config }

  @d.notify('checking credentials')
  check_credentials.call(ctx)
    .with(ctx)
    .then(cd_to_root)
    .then(clean_files)
    .then(upload_files)
    .done((-> d.resolve(name: 'ftp')), d.reject)

  return d.promise

  check_credentials = ->
    deferred = W.defer()

    @client.connect
      host: @config.host,
      port: @config.port || '21'
      user: @config.username,
      password: @config.password

    @client.on 'ready', =>
      @d.notify('authenticated')
      deferred.resolve()

    return deferred.promise

  cd_to_root = ->
    nodefn.call(@client.cwd.bind(@client), @config.root)

  clean_files = (dir) ->
    @d.notify('clearing previous files')

    nodefn.call(@client.list.bind(@client), dir).then (res) ->
      W.map res, (entry) ->
        if entry.name == '.' or entry.name == '..' then return

        if entry.type == 'd'
          clean_files(entry.name)
          .then -> nodefn.call(@client.rmdir.bind(@client), entry.name)
        else
          @d.notify("removing #{dir}/#{entry.name}")
          nodefn.call(@client.delete.bind(@client), "#{dir}/#{entry.name}")

  upload_files = ->
    @d.notify('uploading files via ftp')

    nodefn.call(readdirp, { root: @root })
      .tap (res) -> W.map(_.pluck(res.directories, 'path'), mkdir.bind(@))
      .tap (res) -> W.map(_.pluck(res.files, 'path'), put_file.bind(@))
      .then(@client.end.bind(@client))

  mkdir = (d) ->
    nodefn.call(@client.mkdir.bind(@client), d, true)

  put_file = (f) ->
    @d.notify("uploading #{f}")
    nodefn.call(@client.put.bind(@client), path.join(@root, f), f)

module.exports = FTP
