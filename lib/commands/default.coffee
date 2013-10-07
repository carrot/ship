require 'coffee-script'
arg_parser = require './arg_parser'
colors = require 'colors'

module.exports = (args, env, cb) ->
  args = arg_parser(args, env)
  if args instanceof Error then return cb(args.toString())
  cb(null, args)
