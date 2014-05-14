should = require 'should'
request = require 'request'
require 'shelljs/global'

ship = require '../lib'
BaseDeployer = require '../lib/deployer'

describe 'base deployer', ->
  deployer = new BaseDeployer()

  it 'should take configuration & apply defaults/normalization', ->
    deployer.deploy(
      projectRoot: undefined
      sourceDir: './blah/../test/sample-projects/1'
      ignore: ['ship*.opts', 'blah']
    )
    deployer._config.should.eql(
      projectRoot: './',
      sourceDir: 'test/sample-projects/1',
      ignore: [ 'ship*.opts', 'blah' ]
    )

  it 'should support getFileList()', (done) ->
    deployer.getFileList((err, list) ->
      should.not.exist err
      list.files.length.should.eql 2
      list.files[0].name.should.eql 'ignoreme.html'
      list.files[1].name.should.eql 'index.html'
      done()
    )

describe 's3', ->
  re = /Your site is live at: (http:\/\/.*)/

  it 'should deploy via CLI', (done) ->
    cmd = exec 'bin/ship test/ship.s3.opts', silent: true
    # make sure it returned a url
    cmd.output.should.match(re)
    # hit the url and make sure the site is up
    # and that the ignored file is not
    url = cmd.output.match(re)[1]
    request url, (err, resp, body) ->
      should.not.exist(err)
      body.should.match /look ma, it worked/
      request "#{url}/ignoreme.html", (err, resp, body) ->
        should.not.exist(err)
        resp.statusCode.should.eql(403)
        body.should.not.match /i am a-scared/
        exec 'bin/ship test/ship.s3.opts --delete', silent: true
        done()
