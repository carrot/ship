fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
packageInfo = require(path.join(__dirname, '../package.json'))
ArgumentParser = require('argparse').ArgumentParser

deployers = require './deployers'

argparser = new ArgumentParser(
  version: packageInfo.version
  addHelp: true
  description: packageInfo.description
)
argparser.addArgument(
  ['--deployer', '-d']
  choices: Object.keys(deployers)
  type: 'string'
  help: 'The deployer to use. Selects the first deployer in the config file by default.'
)
argparser.addArgument(
  ['--path', '-p']
  type: 'string'
  defaultValue: './'
  help: 'The path to the root of the project to be shipped. Set to ./ if no path is specified'
)
argparser.addArgument(
  ['--config', '-c']
  type: 'string'
  defaultValue: './ship.json'
  help: 'The path to the config file. Set to ./ship.json if no path is specified'
)
args = argparser.parseArgs()

###*
 * Parse args from the commandline and config file. Also prompt the user for
   any missing info.
###
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

  constructor: (args, env) ->
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

  ###*
   * Ask for an array of config options.
   * @private
   * @return {Array<string>} The array of answers.
  ###
  _prompt: (options) ->
    console.log "please enter the following config details for #{@deployerName.bold}".green
    prompt("#{option}:") for option in options

module.exports = ArgsParser
