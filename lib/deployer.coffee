ConfigSchema = require './config-schema'

###*
 * The base class for all deployers to inherit from. Pretty much stateless
   (the configuration and runtime-specific stuff gets passed to the function,
   not stored).
###
class Deployer
  ###*
   * Holds the schema that manages the configuration.
   * @type {ConfigSchema}
  ###
  configSchema: new ConfigSchema()

  ###*
   * Set schema properties that all deployers use.
   * @extend
  ###
  constructor: ->
    @configSchema.schema.projectRoot =
      required: true
      default: './'
      type: 'string'
    @configSchema.schema.sourceDir =
      required: true
      default: './public'
      type: 'string'

  ###*
   * Run the deployment
   * @param {Object} config The configuration object for the deployer.
   * @return {Promise}
   * @extend
  ###
  deploy: (config) ->
    @configSchema.validate(config)

module.exports = Deployer
