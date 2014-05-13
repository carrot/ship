should = require 'should'
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
