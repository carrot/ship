deployers = require './deployers'

class Ship
  ###*
   * All the deployers we have in ship.
   * @type {Array}
  ###
  deployers: deployers

  ###*
   * [shipFile description]
   * @type {ShipFile}
  ###
  shipFile: undefined

  constructor: (@shipFilePath, @projectRoot) ->

  ###*
   * Run the deployment for a given deployer.
   * @param {String} deployer
   * @return {Promise}
  ###
  deploy: (deployer) ->
    @deployers[deployer].deploy(
      shipFile.getTarget(@projectRoot)
      shipFile.getDeployerConfig(deployer)
    )

module.exports = Ship
