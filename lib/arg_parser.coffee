fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
deployers = require './deployers'

class ArgsParser

  constructor: (args, env) ->
    args ?= []

    # cargo     = the directory of files to be shipped
    # deployer  = specified deployer
    # config    = the shipfile contents
    # path      = the directory the ship command is run in
    # folder    = the relative path to be shipped
    
    @path = process.cwd()

    @errors =
      missing_deployer: "Make sure to specify a deployer!"
      deployer_not_found: "I don't think we have that deployer in stock :("
      path_nonexistant: "It doesn't look like you have specified a path to a folder"

    # $> ship
    if args.length < 1

      # no args, deploy all files within @path from conf file if present
      config = find_conf_file(@path, env)
      if not config then return new Error(@errors.missing_deployer)
      output = { path: @path, config: config, deployer: false, cargo: @path, folder: null }
      return output

    # $> ship s3
    # $> ship path/to/public
    if args.length == 1

      # if the arg passed is a deployer, assume path is cwd
      if is_deployer(args[0]) then return { path: @path, config: find_conf_file(@path, env), deployer: args[0], cargo: @path, folder: null }

      # if the arg passed is not a deployer, assume it's a path
      if not path_exists(args[0]) then return new Error(@errors.path_nonexistant)
      config = find_conf_file(args[0], env)
      if not config then return new Error(@errors.missing_deployer)

    # $> ship path/to/public s3
    if args.length > 1

      # two args, both path and deployer must exist
      if not path_exists(args[0]) then return new Error(@errors.path_nonexistant)
      if not is_deployer(args[1]) then return new Error(@errors.deployer_not_found)
      output = { path: @path, config: find_conf_file(@path, env), deployer: args[1], cargo: path.join(@path, args[0]), folder: args[0] }
      return output

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
