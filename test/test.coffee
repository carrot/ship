fs           = require 'fs'
BaseDeployer = require '../lib/deployer'

describe 'base', ->
  deployer = new BaseDeployer()

  it 'should accept configuration and set defaults', ->
    deployer.deploy(
      projectRoot: undefined
      sourceDir: './blah/../test/fixtures/base'
      ignore: ['ship*.opts', 'blah']
    )
    deployer._config.should.eql(
      projectRoot: './',
      sourceDir: 'test/fixtures/base',
      ignore: [ 'ship*.opts', 'blah' ]
    )

  it 'should return accurate file list', (done) ->
    deployer.getFileList((err, list) ->
      should.not.exist(err)
      list.files.length.should.eql(2)
      list.files[0].name.should.eql('ignoreme.html')
      list.files[1].name.should.eql('index.html')
      done()
    )

describe 's3', ->
  root      = path.join(base_path, 's3')
  opts_path = path.join(root, 'ship.s3.opts')
  maybeIt   = if fs.existsSync(opts_path) then it else it.skip

  maybeIt 'should deploy files to s3 via the CLI', (done) ->
    match = /Your site is live at: (http:\/\/.*)/

    cmd = exec "bin/ship #{opts_path}", silent: true
    cmd.output.should.match(match)
    url = cmd.output.match(match)[1]

    chai.request(url).get('/index.html').res (res) ->
      res.should.have.status(200)
      res.should.be.html
      res.text.should.match /look ma, it worked!/

    chai.request(url).get('/ignoreme.html').res (res) ->
      res.should.have.status(403)
      done()
