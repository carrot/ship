require 'colors'
prompt = require 'prompt'
async = require 'async'

module.exports = (cb) ->
  console.log "please enter the following config details for
  #{@deployers[0].name.bold}".green
  console.log "need help? see http://ship.com/#{@deployer}"

  prompt.message = ''
  prompt.delimiter = ''

  if process.env.NODE_ENV == 'test'
    helpers = require '../test/helpers'
    prompt.start(stdin: helpers.stdin)
  else
    prompt.start()

  keys = Object.keys(@deployers[0].config)
  async.mapSeries(keys, ((k,c) -> prompt.get([k], c)), cb)

