###*
 * The base class for all deployers to inherit from.
###
class Deployer
  name: 'deployer'

  ###*
   * Run the deployment
   * @param {String} path The path to the folder to deploy.
   * @param {Object} config The configuration object for the deployer.
   * @return {Promise}
  ###
  deploy: (path, config) ->

module.exports = Deployer
