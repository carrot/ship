config = require('../config')

describe 'gh-pages', ->

  it 'deploys a basic site to github pages', ->
    project = new Ship(root: path.join(_path, 'deployers/gh-pages'), deployer: 'gh-pages')

    if process.env.TRAVIS
      project.configure
        username: 'shiptester'
        password: config.github.password
        repo: 'shiptester/test'

    project.deploy()
      .should.be.fulfilled
