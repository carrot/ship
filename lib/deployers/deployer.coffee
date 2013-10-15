require 'colors'

class Deployer

  constructor: ->
    @name = 'deployer'
    @config = {}

  deploy: (cb) ->
    console.error('make sure you have defined a deploy method'.red)
    cb()

module.exports = Deployer
