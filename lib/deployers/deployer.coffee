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
   * Run the deployment
   * @param {String} path The path to the folder to deploy.
   * @param {Object} config The configuration object for the deployer.
   * @return {Promise}
  ###
  deploy: (config) ->
    @runDeploy @config.validate(config)

  ###*
   * Do the deployment
   * @param {[type]} config [description]
   * @return {[type]} [description]
   * @extend
  ###
  runDeploy: (config) ->

module.exports = Deployer
