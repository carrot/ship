should = require 'should'
DeployerConfig = require '../lib/deployers/config-schema'
ShipFile = require '../lib/shipfile'

describe 'DeployerConfig', ->
  beforeEach ->
    @deployerConfig = new DeployerConfig()

  it 'should have all the right attributes', ->
    @deployerConfig.schema.should.eql({})
    @deployerConfig.validate({}).should.eql({})

  it 'should validate', ->
    @deployerConfig.schema =
      someOption:
        type: 'boolean'

    @deployerConfig
      .validate(someOption: true)
      .should.eql(someOption: true)

  it 'should throw validate errors', ->
    @deployerConfig.schema =
      someOption:
        type: 'boolean'

    (=> @deployerConfig.validate(someOption: 42)).should.throw(
      'number value found, but a boolean is required'
    )

  it 'should validate individual options', ->
    @deployerConfig.schema =
      someOption:
        type: 'boolean'

    @deployerConfig.validateOption('someOption', true).should.eql(
      errors: []
      valid: true
    )

    @deployerConfig.validateOption('someOption', 42).should.eql(
      errors: ['number value found, but a boolean is required']
      valid: false
    )

  it 'should apply defaults with validate() without mutating @data', ->
    @deployerConfig.schema =
      someOption:
        type: 'boolean'
        default: true

    data = {}
    @deployerConfig.validate(data).should.eql({someOption: true})
    data.should.eql({})

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

  it 'getMissingConfigValues() should work', (done) ->
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
