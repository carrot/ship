fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
deployers = require './deployers'

class ArgsParser

  constructor: (args, env) ->
    args ?= []
    @path = process.cwd()

    @errors =
      missing_deployer: "Make sure to specify a deployer!"
      deployer_not_found: "I don't think we have that deployer in stock :("
      path_nonexistant: "It doesn't look like you have specified a path to a folder"

    # ship
    if args.length < 1

      # no args, deploy all from conf file if present
      config = find_conf_file(process.cwd(), env)
      if not config then return new Error(@errors.missing_deployer)
      return { path: @path, config: config, deployer: false }

    # ship s3
    # ship public/
    if args.length == 1

      # if the arg passed is a deployer, assume path is cwd
      if is_deployer(args[0]) then return { path: @path, config: find_conf_file(@path, env), deployer: args[0] }

      # if the arg passed is not a deployer, assume it's a path
      if not path_exists(args[0]) then return new Error(@errors.path_nonexistant)
      config = find_conf_file(args[0], env)
      if not config then return new Error(@errors.missing_deployer)
      return { path: args[0], config: config, deployer: false }

    # ship public/ s3
    if args.length > 1

      # two args, both path and deployer must exist
      if not path_exists(args[0]) then return new Error(@errors.path_nonexistant)
      if not is_deployer(args[1]) then return new Error(@errors.deployer_not_found)
      return { path: args[0], config: find_conf_file(@path, env), deployer: args[1] }

  # 
  # @api private
  # 
  
  find_conf_file = (p, env) ->
    env = if env? and env != '' then ".#{env}" else ''
    p = path.join(p, "ship#{env}.conf")

    if not fs.existsSync(p) then return false
    return yaml.safeLoad(fs.readFileSync(p, 'utf8'))

  is_deployer = (arg) ->
    Object.keys(deployers).indexOf(arg) > -1

  path_exists = (p) ->
    fs.existsSync(p)

module.exports = ArgsParser
