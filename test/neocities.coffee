path    = require 'path'
node    = require 'when/node'
request = require 'request'
config  = require '../config'

describe 'neocities', ->

  it 'deploys a site to neocities', ->
    project = new Ship(root: path.join(_path, 'deployers/neocities'), deployer: 'neocities')

    if process.env.TRAVIS
      project.configure
        username: 'ship-testing'
        password: config.neocities.password

    project.deploy()
      .tap (res) ->
        node.call(request, res.url)
        .tap (r) -> r[0].body.should.match /neocities deployer working, yay!/
      .then -> project.deploy()
      .catch (err) -> console.error(err); throw err
      .should.be.fulfilled
