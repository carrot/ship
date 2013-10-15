require 'colors'
prompt = require 'prompt'
async = require 'async'

module.exports = (cb) ->
  console.log "please enter the following config details for #{@deployers[0].name.bold}".green
  console.log "need help? see http://ship.com/#{@deployer}"

  prompt.message = ''
  prompt.delimiter = ''
  prompt.start()
  
  async.mapSeries(Object.keys(@deployers[0].config), ((k,c)-> prompt.get([k],c)), cb)

