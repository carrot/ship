describe 'heroku', ->

  it 'deploys a basic site to heroku', ->
    project = new Ship(root: path.join(_path, 'deployers/heroku'), deployer: 'heroku')

    if process.env.TRAVIS
      project.configure
        name: 'ship-testing-app'
        api_key: process.env.HEROKU_API_KEY

    project.deploy()
      .should.be.fulfilled
