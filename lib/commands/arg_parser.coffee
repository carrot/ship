fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
deployers = require '../deployers'

class ArgsParser

  constructor: (args, env) ->

    @errors =
      missing_deployer: "Make sure to specify a deployer!"
      deployer_not_found: "I don't think we have that deployer in stock :("
      path_nonexistant: "It doesn't look like you have specified a path to a folder"

    if args.length < 1

      conf_file = find_conf_file(process.cwd(), env)

      if not conf_file then return new Error(@errors.missing_deployer)

      return { path: process.cwd(), deployer: Object.keys(conf_file)[0] }

    if args.length == 1

      if is_deployer(args[0]) then return { path: process.cwd(), deployer: args[0] }

      if not path_exists(args[0]) then return new Error(@errors.path_nonexistant)

      conf_file = find_conf_file(args[0], env)
      if not conf_file then return new Error(@errors.missing_deployer)

      return { path: args[0], deployer: Object.keys(conf_file)[0] }

    if args.length > 1

      if not path_exists(args[0]) then return new Error(@errors.path_nonexistant)
      if not is_deployer(args[1]) then return new Error(@errors.deployer_not_found)

      return { path: args[0], deployer: args[1] }

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
