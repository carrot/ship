path          = require 'path'
node          = require 'when/node'
fs            = require 'fs'
{parseString} = require 'xml2js'

describe 'cordova', ->

  it 'builds the contents of the root directory into a cordova project', ->

    build_dir = 'build'

    project = new Ship(root: path.join(_path, 'deployers/cordova/public'), deployer: 'cordova')
    progress_spy = sinon.spy()

    project.configure
      package_name : 'com.cordova.test'
      name         : 'CordovaTest'
      platforms    : 'android'
      build_type   : 'release'
      out_dir      : build_dir
      build_app    : false

    project.deploy()
      .progress progress_spy
      .tap -> progress_spy.should.have.been.called
      .tap ->
        node.call fs.readFile, path.resolve(project.root, '..', "#{build_dir}/config.xml")
          .then (contents) -> node.call parseString, contents
          .then (result) -> result.widget.name.should.match /CordovaTest/
      .then (res) -> res.destroy()
      .catch (err) -> console.error(err); throw err
      .should.be.fulfilled
