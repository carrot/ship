require 'coffee-script'
fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
async = require 'async'
colors = require 'colors'
arg_parser = require './arg_parser'
Deployers = require '../deployers'

module.exports = (args, env, cb) ->

  # parse arguments. if it resulted in an error, callback with error
  # args comes back as an object with three keys:
  # - path(str): path to the folder being deployed
  # - config(obj): contents of ship.conf as json
  # - deployer(str): either false (implying all) or a targeted deployer name
  args = arg_parser(args, env)
  if args instanceof Error then return cb(args.toString())

  # if a deployer is provided, we have some interesting options
  if args.deployer

    # there's no config file, set one up for that deployer
    if !args.config
      args.config = config_prompt(Deployers[args.deployer])
      create_config_file(args.path)
      update_config(args.path, args.config)

    # deployer isn't present in the config file, add it
    else if !contains_deployer(args)
      args.config[args.deployer] = config_prompt(Deployers[args.deployer])
      update_config(args.path, args.config)

  # get the correct deployer(s) from the config info
  deployers = if args.deployer then [args.deployer] else Object.keys(args.config)

  # convert the deployer names to actual deployers and configure them
  deployers = deployers.map (name) ->
    d = new Deployers[name](args.path)
    d.configure(args.config)
    return d

  # finally, run the deploy action for each deployer asynchronously
  async.map(deployers, ((d,c) -> d.deploy(c)), cb)

# 
# @api private
# 

contains_deployer = (args) ->
  Object.keys(args.config).indexOf(args.deployer) > -1

config_prompt = (d) ->
  console.log 'prompting the user for configuration'
  return { test: 'foo' }

create_config_file = (p) ->
  console.log "creating conf file at #{path.join(p, 'ship.conf')}"
  # fs.openSync(path.join(p, 'ship.conf'), 'w')

update_config = (p, new_config) ->
  shipfile = path.join(p, 'ship.conf')
  console.log "writing to #{shipfile}"
  console.log yaml.safeDump(new_config)
  # fs.writeFileSync(shipfile, yaml.safeDump(new_config))
