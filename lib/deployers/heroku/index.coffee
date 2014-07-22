W       = require 'when'
nodefn  = require 'when/node'
fs      = require 'fs'
path    = require 'path'
Heroku  = require 'heroku-client'
tar     = require 'tar'
fstream = require 'fstream'
zlib    = require 'zlib'
request = require 'request'

module.exports = (root, opts) ->
  d = W.defer()
  heroku = new Heroku(token: opts.api_key)
  app = heroku.apps(opts.name)

  tar_process = create_tar(root, opts.name).then(upload_tar)

  app_process = W(app.info())
    .catch (err) ->
      if err.body.id isnt 'not_found' then throw err
      W(heroku.apps().create(name: opts.name))
        .then (res) -> app = res

  W.all([tar_process, app_process])
    .then (res) ->
      edge_create_build(heroku, opts.name, res[0])
    .tap (res) ->
      d2 = W.defer()
      stream = request(res.stream_url)
      stream.on('end', d2.resolve)
      stream.on('error', d2.reject)
      stream.on 'data', (data) -> d.notify(String(data))
      return d2.promise
    .tap (res) ->
      d2 = W.defer()
      check_app_status(heroku, res.id, opts.name, d2)
      return d2.promise
    .then (res) -> W(heroku.apps(opts.name).builds(res.id).result().info())
    .finally ->
      fs.unlinkSync(path.join(root, "#{opts.name}.tar.gz"))
    .done =>
      d.resolve
        deployer: 'heroku'
        url: "http://#{opts.name}.herokuapp.com"
        destroy: destroy.bind(@, heroku, opts.name)
    , d.reject

  return d.promise

###*
 * Create a new build using the edge api, which will return a streaming build
 * status url so that we can stream it correctly.
 *
 * @param  {Object} heroku - heroku instance
 * @param  {String} name - app name
 * @param  {String} id - uuid of the tarball
 * @return {Promise} - promise for the created app
###

edge_create_build = (heroku, name, id) ->
  nodefn.call heroku.request.bind(heroku),
    method: 'POST',
    path: "/apps/#{name}/builds",
    headers:
      Accept: 'application/vnd.heroku+json; version=edge',
    body:
      source_blob:
        url: "http://107.170.142.86:1111/#{id}"
        version: id

###*
 * Loops every second to check the build status. Once it is no longer 'pending',
 * allows the process to continue.
 *
 * @todo this should be eliminated, but in testing, sometimes the stream ending
 *       did not correctly indicate a full build, so it's here for security
 *
 * @param  {Object} heroku - heroku instance
 * @param  {Integer} id - app id
 * @param  {String} name - app name
 * @param  {Deferred} d - deferred object
 * @return {Promise} a promise that the app is no longer pending
###

check_app_status = (heroku, id, name, d) ->
  heroku.apps(name).builds(id).info().then (res) ->
    switch res.status
      when 'pending'
        check_app_status(heroku, id, name, d)
      else
        d.resolve()

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
  tar_path = path.join(root, "#{name}.tar.gz")

  stream = fstream.Reader(path: root, type: 'Directory')
    .pipe(tar.Pack(noProprietary: true))
    .pipe(zlib.createGzip())
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
