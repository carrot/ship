ConfigSchema = require 'config-schema'
W = require 'when'

###*
 * Base class for transports
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
      description: 'Path to write to on destination'

  ###*
   * Validate the config & put it in `_config`
   * @param {Object} config
  ###
  configure: (config) ->
    @_config = @configSchema.validate(config)
    @_config.path = path.normalize(@_config.target)

  ###*
   * Resolve a local file path, relative to `_config.path`
   * @param {String} filename
  ###
  resolvePath: (filename) ->
    path.join @_config.path, filename

  ###*
   * Called after sync completes, do any cleanup needed here. close sockets etc.
   * @return {Promise}
  ###
  cleanup: ->
    return when.resolve()

  ###*
   * Callback with a array of filenames and directories in *dirname*.
     Directories should be indicated with a trailing slash (e.g. foo/).
   * @param {String} dirname
   * @return {Promise} Promise for an array of filenames
  ###
  listDirectory: (dirname) ->
    return when.resolve()

  ###*
   * Create *dirname*, ** when done.
   * @param {String} dirname
   * @return {Promise}
  ###
  makeDirectory: (dirname) ->
    return when.resolve()

  ###*
   * Delete directory *dirname*,  when done. Only needs to handle
     empty directories.
   * @param {String} dirname
   * @return {Promise}
  ###
  deleteDirectory: (dirname) ->
    return when.resolve()

  ###*
   * Fetching files: you can choose to implement either of the following
     methods. createReadStream is prefered and will be used first if
     implemented.
  ###

  ###*
   * Return a readable stream for `filename`.
   * @param  {String} filename
   * @return {Promise}
  ###
  getReadStream: (filename) ->

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
  getWriteStream: (filename) ->

  ###*
   * Write *stream* of *size* bytes to `filename`
   * @param {[type]} filename
   * @param {[type]} size
   * @param {[type]} stream
   * @return {Promise}
  ###
  writeFile: (filename) ->

  ###*
   * Delete `filename`
   * @param  {[type]}   filename [description]
   * @return {Promise}
  ###
  deleteFile: (filename) ->

module.exports = Transport
