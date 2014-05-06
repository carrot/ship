path = require 'path'

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
  configSchema: undefined

  ###*
   * Set schema properties that all deployers use.
   * @extend
  ###
  constructor: ->
    # make sure this doesn't get shared between instances
    @configSchema = new ConfigSchema()

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

  ###*
   * Run the deployment
   * @param {Object} config The configuration object for the deployer.
   * @return {Promise}
   * @extend
  ###
  deploy: (config) ->
    config.sourceDir = path.normalize(config.sourceDir)
    config.projectRoot = path.normalize(config.projectRoot)
    @configSchema.validate(config)

module.exports = Deployer
