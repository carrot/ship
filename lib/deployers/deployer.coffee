require 'colors'
path = require 'path'

class Deployer
  name: 'deployer'

  ###*
   * [config description]
   * @attribute [target=process.cwd()] Folder to deploy
   * @attribute [before] Path to before hook script
   * @attribute [after] Path to to after hook script
   * @type {Object.<string, string>}
  ###
  config: {}

  @debug =
    log: (m) -> console.log("#{m}".grey)
    write: (m) -> process.stdout.write("#{m}".grey)

  configure: (slug, data) ->
    @config = data[slug]
    @payload = if @config.target then path.join(@path, @config.target) else process.cwd()

  deploy: (cb) ->
    console.error('make sure you have defined a deploy method'.red)
    cb()

  # this is a method used for testing to ensure commands
  # are being parsed correctly
  mock_deploy: (cb) -> cb()

module.exports = Deployer
