require 'colors'
path = require 'path'

class Deployer

  constructor: ->
    @name = 'deployer'

    # optional global config
    # - target: folder to deploy (default process.cwd())
    # - before: path to before hook script
    # - after: path to after hook script
    
    @debug =
      log: (m) -> console.log("#{m}".grey)
      write: (m) -> process.stdout.write("#{m}".grey)

  configure: (data) ->
    @config = data
    @config.target ||= process.cwd()
    @public = path.join(@path, data.target)

  deploy: (cb) ->
    console.error('make sure you have defined a deploy method'.red)
    cb()

module.exports = Deployer
