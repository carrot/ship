require 'colors'
path = require 'path'

class Deployer

  constructor: ->
    @name = 'deployer'
    @config = {}

  configure: (data) ->
    @config = data
    @public = path.join(@path, data.target)

  deploy: (cb) ->
    console.error('make sure you have defined a deploy method'.red)
    cb()

module.exports = Deployer
