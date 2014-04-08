should = require 'should'
DeployerConfig = require '../lib/deployer-config'

describe 'DeployerConfig', ->
  it 'should have all the right attributes', ->
    deployerConfig = new DeployerConfig()
    deployerConfig.schema.should.eql({})
    deployerConfig.data.should.eql({})

  it 'should validate', ->
    deployerConfig = new DeployerConfig()
    deployerConfig.schema =
      someOption:
        type: 'boolean'

    deployerConfig.data =
      someOption: true

  it 'should throw validate errors', ->
    deployerConfig = new DeployerConfig()
    deployerConfig.schema =
      someOption:
        type: 'boolean'

    deployerConfig.data =
      someOption: 42

    (-> deployerConfig.validate()).should.throw(
      'number value found, but a boolean is required'
    )

  it 'should validate individual options', ->
    deployerConfig = new DeployerConfig()
    deployerConfig.schema =
      someOption:
        type: 'boolean'

    deployerConfig.validateOption('someOption', true).should.eql(
      errors: []
      valid: true
    )

    deployerConfig.validateOption('someOption', 42).should.eql(
      errors: ['number value found, but a boolean is required']
      valid: false
    )

  it 'should apply defaults with validate() without mutating @data', ->
    deployerConfig = new DeployerConfig()
    deployerConfig.schema =
      someOption:
        type: 'boolean'
        default: true

    deployerConfig.validate().should.eql({someOption: true})
    deployerConfig.data.should.eql({})

