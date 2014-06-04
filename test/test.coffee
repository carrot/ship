should = require 'should'
Ship = require '../'
ShipFile = require '../lib/shipfile'

describe 'ShipFile', ->
  it 'should load a config file', (done) ->
    shipFile = new ShipFile('./test/fixtures/ship.json')
    shipFile
      .loadFile()
      .then( ->
        shipFile._config.should.eql(
          foo: 'bar'
          deployers: {}
        )
        done()
      ).catch((e) ->
        done(e)
      )

  it.skip 'getMissingConfigValues() should work', (done) ->
    projectRoot = './test/fixtures/ship.json'
    shipFile = new ShipFile(projectRoot)
    shipFile
      .loadFile()
      .then( ->
        shipFile
          .getMissingConfigValues('ftp', projectRoot)
          .should.eql(['host', 'target', 'username', 'password'])
        done()
      ).catch((e) ->
        done(e)
      )

describe 'Tumblr', ->

  @timeout(20000)

  it 'should throw error with incorrect credentials', (done) ->
    opts =
      deployer: 'tumblr'
      email: 'xxx@xxx.com'
      password: 'xxx'
      blog: 'xxx'
    Ship.deploy(opts)
      .then -> throw new Error()
      .catch (error) -> done()

  it 'should throw error with correct credentials but incorrect file', (done) ->
    opts =
      deployer: 'tumblr'
      email: 'ship@carrotcreative.com'
      password: 'carrotcreative'
      blog: 'shipdeploy'
      file: './test/fixtures/deployers/tumblr/meow.html'
    Ship.deploy(opts)
      .then -> throw new Error()
      .catch (error) -> done()

  it 'should not throw error with correct credentials and correct file', (done) ->
    opts =
      deployer: 'tumblr'
      email: 'ship@carrotcreative.com'
      password: 'carrotcreative'
      blog: 'shipdeploy'
      file: './test/fixtures/deployers/tumblr/index.html'
    Ship.deploy(opts)
      .then (response) -> done()
      .catch (error) -> done(error)
