W       = require 'when'
fs      = require 'fs'
path    = require 'path'
Heroku  = require 'heroku-client'
tar     = require 'tar'
fstream = require 'fstream'
request = require 'request'

module.exports = (root, config) ->
  heroku = new Heroku(token: config.api_key)
  app = heroku.apps(config.name)

  tar_process = create_tar(root, config.name).then(upload_tar)

  app_process = W(app.info())
    .catch (err) ->
      if err.body.id isnt 'not_found' then throw err
      W(heroku.apps().create(name: config.name))
        .then (res) -> app = res

  W.all([tar_process, app_process])
    .then (res) ->
      W(heroku.apps(config.name).builds().create
        source_blob:
          url: "http://107.170.142.86:1111/#{res[0]}"
          version: res[0]
        )
    .then (res) ->
      d = W.defer()
      check_app_status(heroku, res.id, config.name, d)
      return d.promise
    .then (id) -> W(heroku.apps(config.name).builds(id).result().info())
    .tap (res) ->
      console.log res.lines.map((l)-> l.line).join('')
    .finally ->
      fs.unlinkSync(path.join(root, "#{config.name}.tar"))
      destroy(heroku, config.name)

# blarghhhh
check_app_status = (heroku, id, name, d) ->
  heroku.apps(name).builds(id).info().then (res) ->
    switch res.status
      when 'pending'
        process.stdout.write '.'
        check_app_status(heroku, id, name, d)
      else
        d.resolve(res.id)

###*
 * Given a directory path, create a tarball of that directory and drop it as
 * '{name}.tar' at the root of that directory.
 *
 * @private
 * @param {String} root - path to a directory
 * @return {Promise} promise for finished tarballization
###

create_tar = (root, name) ->
  d = W.defer()
  tar_path = path.join(root, "#{name}.tar")

  stream = fstream.Reader(path: root, type: 'Directory')
    .pipe(tar.Pack(noProprietary: true))
    .pipe(fs.createWriteStream(tar_path))

  stream.on('close', d.resolve.bind(d, tar_path))
  stream.on('error', d.reject.bind(d))

  return d.promise

###*
 * Uploads the tarball to a small private api that will host it for exactly one
 * download, then delete it. It's a patch for the fact that for some reason
 * rather than accepting a POST, heroku requires a url where they can download
 * the file. This is running on our server that we are paying for, and we
 * designed the mini api specifically for making this process smooth. Please do
 * not use this service for anything else or attempt to hack or abuse it. It
 * will make us take it down and will ruin the simplicity of this deployer for
 * everyone.
 *
 * @private
 * @return {Promise} a promise for the url that the tarball can be found at
###

upload_tar = (tar_path) ->
  d = W.defer()
  data = []

  stream = fs.createReadStream(tar_path)
    .pipe(request.post('http://107.170.142.86:1111/new'))

  stream.on('data', (d) -> data.push(d))
  stream.on('error', d.reject)
  stream.on('end', -> d.resolve(String(data.join(''))))

  return d.promise

###*
 * Deletes the app from heroku.
 *
 * @private
 * @param  {Object} h - heroku instance
 * @param  {String} name - app name
 * @return {Promise} promise for the deleted app
###

destroy = (h, name) ->
  W(h.apps(name).delete())
