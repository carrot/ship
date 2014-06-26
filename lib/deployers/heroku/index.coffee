W       = require 'when'
fs      = require 'fs'
path    = require 'path'
Heroku  = require 'heroku-client'
tar     = require 'tar'
fstream = require 'fstream'

module.exports = (root, config) ->
  heroku = new Heroku(token: config.api_key)
  app = heroku.apps(config.name)

  tar_process = create_tar(root).then(upload_tar)

  app_process = W(app.info())
    .catch (err) ->
      if err.body.id isnt 'not_found' then throw err
      W(heroku.apps().create(name: config.name))
        .then (res) -> app = res

  W.all([tar_process, app_process])
  #   .then (res) -> W(app.builds.create(url: res[0].url, version: '???'))
  #   .then (res) ->
  #     status = 'pending'

  #     while status is 'pending'
  #       app.builds(res.id).info().then (res) ->
  #         status = res.status
  #         if status is 'pending' then console.log 'deploying...'

  #     res.id
  #   .then (id) -> app.builds(id).result().info()
  #   .tap(console.log)

###*
 * Given a directory path, create a tarball of that directory and drop it as
 * 'pack.tar' at the root of that directory.
 *
 * @param {String} root - path to a directory
 * @return {Promise} promise for finished tarballization
###

create_tar = (root) ->
  d = W.defer()

  stream = fstream.Reader(path: root, type: 'Directory')
    .pipe(tar.Pack(noProprietary: true))
    .pipe(fs.createWriteStream(path.join(root, 'pack.tar')))

  stream.on('close', d.resolve.bind(d))
  stream.on('error', d.reject.bind(d))

  return d.promise

upload_tar = ->
  W.resolve()
  # upload the tar to a DO box with a unique id
  # the DO box will delete the tar after a single download

destroy = (app) ->
  W(app.delete())
