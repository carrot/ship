validate = require('jsonschema').validate

###*
 * The base class for all deployers to inherit from.
###
class Deployer
  ###*
   * JSON-Schema representation of the config. Just the properties object -
     the type & wrapper isn't needed because we assume the config is an object.
   * @type {Object}
  ###
  configPropertiesSchema: {}

  ###*
   * Run the deployment
   * @param {String} path The path to the folder to deploy.
   * @param {Object} config The configuration object for the deployer.
   * @return {Promise}
  ###
  deploy: (path, config) ->
    validate(
      config,
      {
        type: "object"
        properties: @configPropertiesSchema
      }
    )

module.exports = Deployer
