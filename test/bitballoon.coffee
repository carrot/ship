path    = require 'path'
node    = require 'when/node'
request = require 'request'
config  = require '../config'

describe 'bitballoon', ->

  it 'deploys a site to bitballoon', ->
    project = new Ship(root: path.join(_path, 'deployers/bitballoon'), deployer: 'bitballoon')

    if process.env.TRAVIS
      project.configure
        name: 'ship-testing'
        access_token: config.bitballoon.access_token

    project.deploy()
      .catch (err) -> console.error(err); throw err
      .tap (res) ->
        node.call(request, res.url)
        .tap (r) -> r[0].body.should.match /bitballoon deployer working, yay!/
      .then -> project.deploy()
      .catch (err) -> console.error(err); throw err
      .tap (res) -> res.destroy()
      .catch (err) -> console.error(err); throw err
      .should.be.fulfilled
