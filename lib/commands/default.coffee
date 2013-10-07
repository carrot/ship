require 'coffee-script'
async = require 'async'
colors = require 'colors'
arg_parser = require './arg_parser'
deployers = require '../deployers'

module.exports = (args, env, cb) ->
  args = arg_parser(args, env)
  if args instanceof Error then return cb(args.toString())

  deploy_fn = (name, cb2) ->
    console.log name
    deployer = new deployers[name](args.path)
    deployer.deploy(cb2)

  async.map(args.deployers, deploy_fn, cb)
