ConfigSchema = require 'config-schema'
path     = require 'path'
readdirp = require 'readdirp'
W        = require 'when'
_        = require 'lodash'


###*
 * The base class for all deployers to inherit from.
###
class Deployer
  ###*
   * Holds the schema that manages the configuration.
   * @type {ConfigSchema}
  ###
  configSchema: undefined

  ###*
   * The current configuration object for the deployer (prevents us from
     needing to pass configuration items around). This object may be mutated
     from what the configSchema defines after deployment starts.
   * @private
   * @type {Object}
  ###
  _config: undefined

  ###*
   * Set schema properties that all deployers use.
   * @extend
  ###
  constructor: ->
    # make sure these don't get shared between instances
    @configSchema = new ConfigSchema()
    @_config = {}

    @configSchema.schema.projectRoot =
      required: true
      default: './'
      type: 'string'
      description: 'The path to the root of the project to be shipped.'
    @configSchema.schema.sourceDir =
      required: true
      default: './public'
      type: 'string'
      description: ''
    @configSchema.schema.ignore =
      required: true
      default: ['ship*.opts']
      type: 'array'
      description: 'Minimatch-style strings for what files to ignore.
      This can be repeated to add multiple ignored patterns.'

  ###*
   * Run the deployment
   * @param {Object} config The configuration object for the deployer.
   * @return {Promise} Actually, only the extended functions return a promise.
     The base one doesn't because we need to call it with super
   * @extend
  ###
  deploy: (config) ->
    @_config = @configSchema.validate(config)
    @_config.sourceDir = path.normalize(@_config.sourceDir)
    @_config.projectRoot = path.normalize(@_config.projectRoot)

  ###*
   * Get the list of files to be deployed, taking into account the ignored
     files.
   * @param {Function} [cb] An optional callback.
   * @return {Stream} A readdirp Stream (if `cb` isn't passed)
  ###
  getFileList: (cb) ->
    ignored = @_config.ignore.map (v) -> "!#{v}"
    readdirp
      root: @_config.sourceDir
      fileFilter: ignored
      directoryFilter: ignored
      cb

module.exports = Deployer
