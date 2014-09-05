path   = require 'path'
fs     = require 'fs'
yaml   = require 'js-yaml'
prompt = require './prompt'
W      = require 'when'
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
    @conf = if opts.conf then path.resolve(opts.conf)
    @deployer_name = opts.deployer
    @env = opts.env
    @shipfile = find_shipfile.call(@)

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
    if fs.existsSync(@shipfile) then return true
    false

  ###*
   * Manually sets the deployer's config/auth values.
   *
   * @param  {Object} data - deployer config values, see deployer docs for more
  ###

  configure: (data) ->
    config_keys = @deployer.config?.required
    if config_keys and not contains_keys(config_keys, Object.keys(data))
      throw new Error("you must specify these keys: #{config_keys.join(' ')}")
    data.ignore ?= []
    data.ignore.push('**/ship*.conf')
    @config = data

  ###*
   * Prompts the user for the deployer's config values via command line and sets
   * the resulting values as the instance's configuration.
   *
   * @return {Promise} promise for the configured values
   * @todo actually return a promise
  ###

  config_prompt: ->
    prompt(@deployer_name, @deployer.config?.required)
      .tap((res) => @config = res)

  ###*
   * Writes the config values of the instance to `ship.conf` at the project
   * root, if the instance has been configured.
   *
   * @return {Promise} promise for the written config file
  ###

  write_config: (override) ->
    if not @config then return W.reject('deployer has not yet been configured')
    conf = {}; conf[@deployer_name] = @config
    nodefn.call(fs.writeFile, (override or @shipfile), yaml.safeDump(conf))

  ###*
   * Deploy the files at project root with the given deployer. Returns a promise
   * that emits progress events along the way.
   *
   * @return {Promise} promise for finished deploy
  ###

  deploy: (target) ->
    target ?= @root

    if not @config
      if not fs.existsSync(@shipfile)
        return W.reject('you must configure the deployer')

      try @configure(load_shipfile.call(@))
      catch err then return W.reject(err)

    @deployer(target, @config)

  ###*
   * Given two arrays, ensure that the second array contains all values provided
   * in the first array. This is for checking to ensure all config values are
   * present.
   *
   * @private
   * @param  {Array} set1 - user-provided keys
   * @param  {Array} set2 - config-required keys
   * @return {Boolean} if all keys in set1 are also present in set2
  ###

  contains_keys = (set1, set2) ->
    _.isEqual(_.intersection(set2, set1).sort(), set1.sort())

  ###*
   * Determines the path to the Shipfile. It uses the conf option if present,
   * otherwise it looks in root, then the current working directory. If neither
   * exist, it sets the shipfile to be inside root.
   *
   * @private
   * @return {String} - path to shipfile
  ###

  find_shipfile = ->
    p = (dir) => path.join(dir, "ship#{if @env then '.' + @env else ''}.conf")
    if @conf then return p(@conf)
    _.find(_.map([@root, process.cwd()], p), fs.existsSync) || p(process.cwd())

  ###*
   * Loads the configuration for the specified deployer from the shipfile.
   *
   * @private
   * @return {Object} - relevant config info
  ###

  load_shipfile = ->
    yaml.safeLoad(fs.readFileSync(@shipfile, 'utf8'))[@deployer_name]

module.exports = Ship
