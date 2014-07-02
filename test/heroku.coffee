describe 'heroku', ->

  it 'deploys a basic site to heroku', ->
    project = new Ship(root: path.join(_path, 'deployers/heroku'), deployer: 'heroku')

    if process.env.TRAVIS
      project.configure
        name: 'ship-testing-app'
        api_key: '8849ba7a0462bc4efe4d242e465bc414f99f1b12'

    project.deploy()
      .should.be.fulfilled
