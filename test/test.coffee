should = require 'should'
DeployerConfig = require '../lib/deployer-config'
ShipFile = require '../lib/shipfile'

describe 'DeployerConfig', ->
  beforeEach ->
    @deployerConfig = new DeployerConfig()

  it 'should have all the right attributes', ->
    @deployerConfig.schema.should.eql({})
    @deployerConfig.data.should.eql({})

  it 'should validate', ->
    @deployerConfig.schema =
      someOption:
        type: 'boolean'

    @deployerConfig.data =
      someOption: true

  it 'should throw validate errors', ->
    @deployerConfig.schema =
      someOption:
        type: 'boolean'

    @deployerConfig.data =
      someOption: 42

    (=> @deployerConfig.validate()).should.throw(
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

    @deployerConfig.validate().should.eql({someOption: true})
    @deployerConfig.data.should.eql({})

describe 'ShipFile', ->
  it 'load a config file', (done) ->
    shipFile = new ShipFile('./test/fixtures/ship.json')
    shipFile
      .loadFile()
      .then(
        () ->
          shipFile._config.should.eql(foo: 'bar')
          done()
        (err) ->
          done(err)
      )
