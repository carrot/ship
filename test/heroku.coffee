config = require('../config')

describe 'heroku', ->

  it 'deploys a basic site to heroku', ->
    project = new Ship(root: path.join(_path, 'deployers/heroku'), deployer: 'heroku')

    if process.env.TRAVIS
      project.configure
        name: 'ship-testing-app'
        api_key: config.heroku.api_key

    project.deploy()
      .should.be.fulfilled
