File = require 'fobject'
deployers = require './deployers'
_ = require 'lodash'

class ShipFile
  ###*
   * The file object that represents the raw shipfile.
   * @type {File}
  ###
  file: undefined

  ###*
   * The parsed configuration.
   * @attribute target Folder to deploy, always relative to the project root.
     It isn't relative to the shipfile because the shipfile isn't necessarily
     in the project (even though that's the normal place to keep it)
   * @attribute deployers={} A hash of deployer configurations. Each key is
     the deployer name, and the value is the _config object.
   * @attribute [before] Path to before hook script
   * @attribute [after] Path to to after hook script
   * @type {Object.<string>}
   * @private
  ###
  _config: {}

  ###*
   * @param {String} path The path to the ShipFile
  ###
  constructor: (path) ->
    @file = new File(path)

  ###*
   * Get the data from the raw config file & put it in ShipFile._config.
   * @return {Promise}
  ###
  loadFile: ->
    @file.read(encoding: 'utf8').then((data) => @config = JSON.parse(data))

  ###*
   * Update the config file with all the data from ShipFile._config. This
     method needs to be called before the program ends or config changes will
     be lost.
   * @return {Promise}
  ###
  updateFile: ->
    @file.write(JSON.stringify(@_config, null, 2))

  ###*
   * Get the path to the folder to deploy.
   * @param {String} projectRoot
  ###
  getTarget: (projectRoot) ->
    #TODO: normalize path by getting root to project
    @_config.target

  ###*
   * Change the folder to deploy.
   * @param {String} path
  ###
  setTarget: (path) ->
    @_config.target = path

  ###*
   * @param {String} [deployer = @getDefaultDeployer()]
   * @return {Object} Deployer config.
  ###
  getDeployerConfig: (deployer = @getDefaultDeployer()) ->
    @_config.deployers[deployer]

  ###*
   * Set the config for a deployer. Will merge in values if only a partial
     object is supplied.
   * @param {String} [deployer = @getDefaultDeployer()]
   * @param {Object} config
  ###
  setDeployerConfig: (deployer = @getDefaultDeployer(), config) ->
    # simple flat merge
    for key, value of config
      @_config.deployers[deployer][key] = value

  ###*
   * Get the default deployer. If `defaultDeployer` isn't in the config, and
     there's only 1 deployer in the config we can assume that is what we want
     to depoy with.
   * @return {String} deployer
  ###
  getDefaultDeployer: ->
    if @_config.defaultDeployer?
      return @_config.defaultDeployer
    else if (keys = Object.keys(@_config.deployers)).length is 1
      @setDefaultDeployer keys[0] # make it explicit
      return keys[0]
    else
      throw new NoDefaultDeployerException()

  ###*
   * Change the default deployer.
   * @param {String} deployer
  ###
  setDefaultDeployer: (deployer) ->
    @_config.defaultDeployer = deployer

  ###*
   * Get all the config values that need to be filled in.
   * @param {String} [deployer = @getDefaultDeployer()]
   * @return {Array<String>}
  ###
  getMissingConfigValues: (deployer = @getDefaultDeployer()) ->
    _.without(
      _.keys(@_config.deployers[deployer])
      _.keys(deployers[deployer].configPropertiesSchema)...
    )


class NoDefaultDeployerException extends Error
  message: 'Can\'t find a default deployer. Specify one in the ShipFile or use the --deployer arg.'

  constructor: (@message=@message) ->
    super @message

module.exports = ShipFile
