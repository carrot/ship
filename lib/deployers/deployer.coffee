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

  configure: (slug, data) ->
    @config = data[slug]
    @payload = if @config.target
      path.join(@path, @config.target)
    else
      process.cwd()

  deploy: (cb) ->
    console.error('make sure you have defined a deploy method'.red)
    cb()

  # this is a method used for testing to ensure commands
  # are being parsed correctly
  mock_deploy: (cb) -> cb()

module.exports = Deployer
