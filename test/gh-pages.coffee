config = require '../config'

describe 'gh-pages', ->

  it 'deploys a basic site to github pages', ->
    project = new Ship(root: path.join(_path, 'deployers/gh-pages'), deployer: 'gh-pages')

    if process.env.TRAVIS
      project.configure
        username: 'shiptester'
        password: config.github.password
        repo: 'shiptester/test'

    project.deploy()
      .catch (err) -> console.error(err); throw err
      .then (res) -> res.destroy()
      .catch (err) -> console.error(err); throw err
      .should.be.fulfilled

  it 'deploys a site without the gh-pages branch present', ->
    project = new Ship(root: path.join(_path, 'deployers/gh-pages2'), deployer: 'gh-pages')

    if process.env.TRAVIS
      project.configure
        username: 'shiptester'
        password: config.github.password
        repo: 'shiptester/test2'

    project.deploy()
      .catch (err) -> console.error(err); throw err
      .then (res) -> res.destroy()
      .catch (err) -> console.error(err); throw err
      .should.be.fulfilled

