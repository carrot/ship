DeployerConfig = require '../deployer-config'

###*
 * The base class for all deployers to inherit from.
###
class Deployer
  ###*
   * @type {DeployerConfig}
  ###
  config: new DeployerConfig()

  ###*
   * Run the deployment
   * @param {String} path The path to the folder to deploy.
   * @param {Object} config The configuration object for the deployer.
   * @return {Promise}
  ###
  deploy: (@path, config) ->
    @config.data = config


module.exports = Deployer
