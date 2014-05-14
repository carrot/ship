ConfigSchema = require 'config-schema'
W = require 'when'
path = require 'path'

###*
 * @typedef Stat
 * @type {Object}
 * @property {String} type A single character denoting the entry type: 'd' for
   directory, 'f' for file, and 'l' for symlink.
###

###*
 * Base class for transports
 * @todo Make a way to do "nearly atomic uploads" by uploading to a tmp dir
   and then renaming to the target dir
###
class Transport
  ###*
   * Holds the schema that manages the configuration.
   * @type {ConfigSchema}
  ###
  configSchema: undefined

  ###*
   * The current configuration object for the transport (prevents us from
     needing to pass configuration items around). This object may be mutated
     from what the configSchema defines after sync starts.
   * @private
   * @type {Object}
  ###
  _config: undefined

  ###*
   * By default, it just sets schema properties that all transports use.
   * @extend
  ###
  constructor: ->
    # make sure these don't get shared between instances
    @configSchema = new ConfigSchema()
    @_config = {}

    @configSchema.schema.path =
      required: true
      type: 'string'
      default: '/'
      description: 'Path to write to on destination'

  ###*
   * Validate the config & put it in `_config`
   * @param {Object} config
   * @return {Promise}
  ###
  config: (config) ->
    @_config = @configSchema.validate(config)
    @_config.path = path.normalize(@_config.path)
    W.resolve()

  ###*
   * Resolve a local file path, relative to `_config.path`
   * @param {String} filename
  ###
  #resolvePath: (filename) ->
  #  path.join @_config.path, filename

  ###*
   * Called after sync completes, do any cleanup needed here. close sockets etc.
   * @return {Promise}
  ###
  cleanup: ->

  ###*
   * Callback with a array of filenames and directories in *dirname*.
   * @param {String} dirname
   * @return {Promise} Promise for an array of filenames
  ###
  ls: (dirname) ->

  ###*
   * Get info about a path.
   * @todo Implement some sort of optional caching.
   * @param {String} path [description]
   * @return {Promise} A Promise for a Stat Object.
  ###
  stat: (path) ->

  ###*
   * Create `dirname`. Will create parent directories by default.
   * @param {String} dirname
   * @return {Promise}
  ###
  mkdir: (dirname) ->

  ###*
   * Return a readable stream for `filename`.
   * @param  {String} filename
   * @return {Promise}
  ###
  createReadStream: (filename) ->

  ###*
   * Read a file.
   * @param  {String} filename
   * @return {Promise}
  ###
  readFile: (filename) ->

  ###*
   * Return a writeable stream for `filename`.
   * @param  {String} filename
   * @return {Promise}
  ###
  createWriteStream: (filename) ->

  ###*
   * Write `filename` to `path`
   * @param {String} filename
   * @param {String} path The path to write to.
   * @return {Promise}
  ###
  writeFile: (filename, path) ->

  ###*
   * Delete/remove `path`.
   * @param  {[type]}   filename [description]
   * @return {Promise}
  ###
  rm: (path) ->

  ###*
   * Rename/move `oldPath` to `newPath`.
   * @return {Promise}
  ###
  mv: (oldPath, newPath) ->

module.exports = Transport
