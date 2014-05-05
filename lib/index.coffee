deployers = require './deployers'

###*
 * Run the deployment for a given deployer.
 * @param {Object} config
 * @return {Promise}
###
module.exports.deploy = (config) ->
  deployer = new deployers[config.deployer]()
  delete config.deployer
  deployer.deploy(config)
