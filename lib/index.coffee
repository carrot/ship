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

  constructor: (@shipFile, @projectRoot) ->

  ###*
   * Run the deployment for a given deployer.
   * @param {String} deployer
   * @return {Promise}
  ###
  deploy: (deployer) ->
    config = @shipFile.getDeployerConfig(deployer, @projectRoot)
    (new @deployers[deployer]).deploy(config)

module.exports = Ship
