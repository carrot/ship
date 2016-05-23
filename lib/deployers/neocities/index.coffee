NeoCities = require 'neocities'
W         = require 'when'
callbacks = require 'when/callbacks'
nodefn    = require 'when/node/function'
readdirp  = require 'readdirp'
path      = require 'path'

# https://neocities.org/site_files/allowed_types
allowed_types = [
  # HTML
  '.html', '.htm'
  # Image
  '.jpg', '.png', '.gif', '.svg', '.ico'
  # Markdown
  '.md', '.markdown'
  # JavaScript
  '.js', '.json', '.geojson'
  # CSS
  '.css'
  # Text
  '.txt', '.text', '.csv', '.tsv'
  # XML
  '.xml'
  # Web Fonts
  '.eot', '.ttf', '.woff', '.woff2', '.svg'
  # MIDI Files
  '.mid', '.midi'
]

module.exports = (root, config) ->
  d = W.defer()

  client = new NeoCities(config.username, config.password)

  W().with(root: root, client: client, config: config, d: d)
    .then(lookup)
    .then(deploy)
    .done (site) ->
      d.resolve
        deployer: 'neocities'
        url: "http://#{config.username}.neocities.org"
    , d.reject

  return d.promise

module.exports.config =
  required: ['username', 'password']

###*
 * Checks to see if your site is already on neocities or not. Returns either a
 * site object or undefined.
 * @return {Promise} promise for either undefined or a site object
###

lookup = ->
  callbacks.call(@client.info.bind(@client))
    .then (res) -> verify(res)

###*
 * Creates a new deploy for a given site with the contents of the root.
 * @return {Promise} a promise for a finished deployment
###

deploy = ->
  @d.notify("Deploying '#{@config.username}'")
  nodefn.call(readdirp, { root: @root })
    .then (res) =>
      files = res.files
        .filter (f) -> allowed_types.indexOf(path.extname(f.name)) >= 0
        .map (f) => name: f.path, path: path.join(@root, f.path)
      callbacks.call(@client.upload.bind(@client), files)
        .then (res) -> verify(res)

###*
 * Verify that the neocities API did not encounter an error.
 * @param  {Object} result - a result object from neocities
 * @return {Object} the result object, if no error was found
###

verify = (result) ->
  if result.result == 'error' then throw new Error(result.message) else result
