path   = require 'path'
fs     = require 'fs'
yaml   = require 'js-yaml'
prompt = require './prompt'
nodefn = require 'when/node'
_      = require 'lodash'

class Ship

  ###*
   * Creates a new ship instance. Throws if you have not specified a valid
   * deployer or folder to ship.
   *
   * @param  {Object} opts - object with keys `root` and `deployer`
  ###

  constructor: (opts) ->
    @root = path.resolve(opts.root)
    @deployer_name = opts.deployer

    try @deployer = require("./deployers/#{opts.deployer}")
    catch err then throw new Error("#{opts.deployer} is not a valid deployer")

    if not fs.existsSync(@root)
      throw new Error("path #{@root} does not exist")

  ###*
   * Tests whether the ship instance has been configured or there is a shipfile
   * present that it can use to configure.
   *
   * @return {Boolean} - whether or not you need to configure the instance
  ###

  is_configured: ->
    if @config then return true
    if fs.existsSync(path.join(@root, 'ship.conf')) then return true
    false

  ###*
   * Manually sets the deployer's config/auth values.
   *
   * @param  {Object} data - deployer config values, see deployer docs for more
  ###

  configure: (data) ->
    config_keys = @deployer.config.required
    if not contains_keys(config_keys, Object.keys(data))
      throw new Error("you must specify these keys: #{config_keys.join(' ')}")
    @config = data

  ###*
   * Prompts the user for the deployer's config values via command line and sets
   * the resulting values as the instance's configuration.
   *
   * @return {Promise} promise for the configured values
   * @todo actually return a promise
  ###

  config_prompt: ->
    prompt(@deployer_name, @deployer.config.required)
    .tap((res) => @config = res)

  ###*
   * Writes the config values of the instance to `ship.conf` at the project
   * root, if the instance has been configured.
   *
   * @return {Promise} promise for the written config file
  ###

  write_config: ->
    if not @config then throw new Error('deployer has not yet been configured')
    dest = path.join(@root, 'ship.conf')
    conf = {}; conf[@deployer_name] = @config
    nodefn.call(fs.writeFile, dest, yaml.safeDump(conf))

  ###*
   * Deploy the files at project root with the given deployer. Returns a promise
   * that emits progress events along the way.
   *
   * @return {Promise} promise for finished deploy
  ###

  deploy: ->
    if not @config
      shipfile = path.join(@root, 'ship.conf')

      if not fs.existsSync(shipfile)
        throw new Error('you must configure the deployer')

      @config = yaml.safeLoad(shipfile)[@deployer_name]

      # diff the deployer's keys and the keys in @config, if they differ
      # throw an error with the missing keys noted

    @deployer(@root, @config)

  ###*
   * Given two arrays, ensure that the second array contains all values provided
   * in the first array. This is for checking to ensure all config values are
   * present.
   *
   * @param  {Array} set1 - user-provided keys
   * @param  {Array} set2 - config-required keys
   * @return {Boolean} if all keys in set1 are also present in set2
  ###

  contains_keys = (set1, set2) ->
    _.isEqual(_.intersection(set2, set1), set2)

module.exports = Ship
