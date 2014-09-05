mockery = require 'mockery'
W       = require 'when'

mock_spy = null
options_spy = null
fail_deploy_flag = false
configured_flag = false

class ShipMock
  constructor: (opts) ->
    options_spy = opts
    mock_spy = sinon.spy()
    if not opts.deployer then throw 'no deployer provided'
  is_configured: ->
    configured_flag
  config_prompt: ->
    mock_spy('config_prompt')
    W.resolve()
  write_config: ->
    mock_spy('write_config')
    W.resolve()
  deploy: ->
    mock_spy('deploy')
    if fail_deploy_flag
      W.reject('such fail')
    else
      W.resolve(deployer: 'test')

describe 'cli', ->

  before ->
    mockery.enable(warnOnUnregistered: false)
    mockery.registerMock('./index', ShipMock)
    @cli = new (require('../lib/cli'))(debug: true)

  it 'errors if no deployer is specified', (done) ->
    @cli.once 'err', (err) ->
      err.should.equal('no deployer provided')
      done()
    @cli.run('')

  it 'errors if there is a problem with the deploy', (done) ->
    fail_deploy_flag = true
    @cli.once 'err', (err) ->
      err.should.equal('such fail')
      fail_deploy_flag = false
      done()
    @cli.run('-to nowhere')

  it 'prompts for config values if no shipfile, writes collected values', (done) ->
    @cli.once('err', done)
    @cli.once 'success', ->
      mock_spy.should.have.been.calledWith('config_prompt')
      mock_spy.should.have.been.calledWith('write_config')
      done()
    @cli.run("-to nowhere")

  it 'deploys a path that is passed as a positional argument', (done) ->
    @cli.once('err', done)
    @cli.once 'success', ->
      options_spy.root.should.equal('wow')
      done()
    @cli.run("wow -to nowhere")

  it 'deploys cwd if no positional argument is passed', (done) ->
    @cli.once('err', done)
    @cli.once 'success', ->
      options_spy.root.should.equal(process.cwd())
      done()
    @cli.run("-to nowhere")

  it 'deploys using the deployer specified as a -to option', (done) ->
    @cli.once('err', done)
    @cli.once 'success', ->
      options_spy.deployer.should.equal('dogeroku')
      done()
    @cli.run("-to dogeroku")

  it 'deploys using an environment if -e is passed', (done) ->
    @cli.once('err', done)
    @cli.once 'success', ->
      options_spy.env.should.equal('foo')
      done()
    @cli.run("-to nowhere -e foo")

  it 'deploys using an custom ship.conf directory if -c is passed', (done) ->
    dir = 'conf_dir'
    @cli.once('err', done)
    @cli.once 'success', ->
      options_spy.conf.should.equal(dir)
      done()
    @cli.run("-to nowhere -c #{dir}")

  after ->
    mockery.deregisterAll()
    mockery.disable()
