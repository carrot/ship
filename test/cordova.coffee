path          = require 'path'
node          = require 'when/node'
fs            = require 'fs'
{parseString} = require 'xml2js'

describe 'cordova', ->

  it 'builds the contents of the root directory into a cordova project', ->

    project = new Ship(root: path.join(_path, 'deployers/cordova'), deployer: 'cordova')
    progress_spy = sinon.spy()

    if process.env.TRAVIS
      project.configure
        package_name: 'com.cordova.test'
        name: 'CordovaTest'
        platforms: 'android'
        build_type: 'release'

    project.deploy()
      .progress progress_spy
      .tap -> progress_spy.should.have.been.called
      .tap (res) ->
        node.call fs.readFile, path.resolve(project.root, '..', 'cordova/config.xml')
          .then (contents) -> node.call parseString, contents
          .tap (result) ->
            result.widget.name.should.match /CordovaTest/
      .then (res) -> res.destroy()
      .catch (err) -> console.error(err); throw err
      .should.be.fulfilled
