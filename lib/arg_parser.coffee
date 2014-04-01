fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
deployers = require './deployers'

class ArgsParser
  ###*
   * Bunch of error strings.
   * @todo make these into actual exception types that you can throw.
   * @type {Object}
   * @const
   * @private
  ###
  _errors:
    MISSING_DEPLOYER: 'Make sure to specify a deployer!'
    DEPLOYER_NOT_FOUND: 'I don\'t think we have that deployer'
    PATH_NONEXISTANT: 'It doesn\'t look like you have specified a path to a folder'

  constructor: (args=[], env) ->
    @path = process.cwd()

    # ship
    if args.length < 1
      # no args, deploy all from conf file if present
      config = @_findConfFile(@path, env)
      if not config then throw new Error(@_errors.MISSING_DEPLOYER)
      return {
        path: @path
        config: config
        deployer: false
      }

    # ship s3
    # ship public/
    if args.length is 1
      # if the arg passed is a deployer, assume path is cwd
      if @_isDeployer(args[0])
        return {
          path: @path
          config: @_findConfFile(@path, env)
          deployer: args[0]
        }

      # if the arg passed is not a deployer, assume it's a path
      if not @_pathExists(args[0])
        throw new Error(@_errors.PATH_NONEXISTANT)

      config = @_findConfFile(args[0], env)
      if not config then throw new Error(@_errors.MISSING_DEPLOYER)
      return {
        path: args[0]
        config: config
        deployer: false
      }

    # ship public/ s3
    if args.length > 1
      # two args, both path and deployer must exist
      if not @_pathExists(args[0])
        throw new Error(@_errors.PATH_NONEXISTANT)
      if not @_isDeployer(args[1])
        throw new Error(@_errors.DEPLOYER_NOT_FOUND)

      return {
        path: args[0]
        config: @_findConfFile(@path, env)
        deployer: args[1]
      }

  ###*
   * @private
  ###
  _findConfFile: (p, env) ->
    env = if env? and env isnt '' then ".#{env}" else ''
    p = path.join(p, "ship#{env}.conf")

    if not fs.existsSync(p) then return false
    return yaml.safeLoad(fs.readFileSync(p, 'utf8'))

  ###*
   * @private
  ###
  _isDeployer: (arg) ->
    Object.keys(deployers).indexOf(arg) > -1

  ###*
   * @private
  ###
  _pathExists: (p) ->
    fs.existsSync(p)

module.exports = ArgsParser
