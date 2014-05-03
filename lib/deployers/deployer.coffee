DeployerConfigSchema = require './config-schema'

###*
 * The base class for all deployers to inherit from. Pretty much stateless
   (the configuration and runtime-specific stuff gets passed to the function,
   not stored).
###
class Deployer
  ###*
   * @type {DeployerConfigSchema}
  ###
  config: new DeployerConfigSchema()

  ###*
   * Set schema properties that all deployers use.
  ###
  constructor: ->
    @config.schema.projectRoot =
      required: true
      default: './'
      type: 'string'
    @config.schema.sourceDir =
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
    @config.validate(config)

module.exports = Deployer
