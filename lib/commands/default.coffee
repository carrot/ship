require 'coffee-script'
fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
async = require 'async'
colors = require 'colors'
prompt = require 'prompt'
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

  # - make sure configuration for each deployer is set up correctly
  # - run the deploy action for each deployer asynchronously
  configure_deployers args, (deployers) ->
    async.map(deployers, ((d,c) -> d.deploy(c)), cb)

# 
# @api private
# 

configure_deployers = (args, cb) ->

  # if a deployer is provided, we have some interesting options
  setup_new_deployer args, (args) ->

    # get the correct deployer(s) from the config info
    deployers = if args.deployer then [args.deployer] else Object.keys(args.config)

    # convert the deployer names to actual deployers and configure them
    cb deployers.map (name) ->
      deployer = new Deployers[name](args.path)
      deployer.config = args.config
      return deployer

setup_new_deployer = (args, cb) ->
  # if there is no deployer in the args, setup not needed
  if !args.deployer then return cb(args)

  # there's no config file, set one up for that deployer
  if !args.config
    config_prompt new Deployers[args.deployer](args.path), (err, res) ->
      args.config = {}
      args.config[args.deployer] = res
      create_config_file(args.path)
      update_config(args.path, args.config)
      cb(args)

  # deployer isn't present in the config file, add it
  else if !contains_deployer(args)
    config_prompt Deployers[args.deployer], (err, res) ->
      args.config[args.deployer] = res
      update_config(args.path, args.config)
      cb(args)

contains_deployer = (args) ->
  Object.keys(args.config).indexOf(args.deployer) > -1

config_prompt = (d, cb) ->

  console.log "please enter the following config details for #{d.name.bold}".green
  console.log "need help? see #{'HELP URL'}".grey

  prompt.start()
  async.mapSeries(Object.keys(d.config), ((k,c)-> prompt.get([k],c)), cb)

create_config_file = (p) ->
  console.log "creating conf file"
  # fs.openSync(path.join(p, 'ship.conf'), 'w')

update_config = (p, new_config) ->
  shipfile = path.join(p, 'ship.conf')
  console.log "updating conf file"
  console.log yaml.safeDump(new_config)
  # fs.writeFileSync(shipfile, yaml.safeDump(new_config))
