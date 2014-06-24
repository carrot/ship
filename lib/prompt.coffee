require 'colors'
prompt   = require 'prompt'
sequence = require 'when/sequence'

module.exports = (name, required) ->
  console.log "please enter the following config details for
  #{name.bold}".green
  console.log "need help? see http://ship.com/#{name}"

  prompt.message = ''
  prompt.delimiter = ''

  if process.env.NODE_ENV == 'test'
    helpers = require '../test/helpers'
    prompt.start(stdin: helpers.stdin)
  else
    prompt.start()

  keys = Object.keys(required)
  sequence(keys, ((k) -> nodefn.call(prompt.get, [k])))
