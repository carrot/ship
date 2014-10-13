request = require 'request'
nodefn  = require 'when/node'
config  = require '../config'
path    = require 'path'

describe 'gh-pages', ->

  it 'deploys a complex nested site to an empty repo', ->
    project = new Ship(root: path.join(_path, 'deployers/gh-pages'), deployer: 'gh-pages')

    if process.env.TRAVIS
      project.configure
        username: 'shiptester'
        password: config.github.password
        repo: 'shiptester/test'

    project.deploy()
      .tap ->
        nodefn.call(request, "https://raw.githubusercontent.com/shiptester/test/gh-pages/index.html")
        .tap (r) -> r[0].body.should.match /Testing Page/
      .then (res) -> res.destroy()
      .catch (err) -> console.error(err); throw err
      .should.be.fulfilled

  it 'deploys a site to gh-pages when master is already present', ->
    project = new Ship(root: path.join(_path, 'deployers/gh-pages2'), deployer: 'gh-pages')

    if process.env.TRAVIS
      project.configure
        username: 'shiptester'
        password: config.github.password
        repo: 'shiptester/test2'

    project.deploy()
      .tap ->
        nodefn.call(request, "https://raw.githubusercontent.com/shiptester/test2/gh-pages/index.html")
        .tap (r) -> r[0].body.should.match /wow/
      .then (res) -> res.destroy()
      .catch (err) -> console.error(err); throw err
      .should.be.fulfilled

