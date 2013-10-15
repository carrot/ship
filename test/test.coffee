should = require 'should'
cmd = require '../lib/commands'
path = require 'path'
test_dir = path.join(process.cwd(), 'test')

process.env.NODE_ENV = 'test'

describe 'commands', ->

  it 'should error when 0 args, no ship.conf', (done) ->
    process.chdir path.join(test_dir, 'no_ship_conf')

    (new cmd.default).run (err, res) ->
      err.should.match /specify a deployer/
      done()

  it 'should succeed when 0 args, ship.conf has multiple deployers', (done) ->
    process.chdir('../multiple_deployers')

    (new cmd.default).run (err, res) ->
      should.not.exist(err)
      done()

  it 'should succeed when 0 args, ship.conf w/ one deployer', (done) ->
    process.chdir('../one_deployer')

    (new cmd.default).run (err, res) ->
      should.not.exist(err)
      done()

  it 'should succeed when 1 arg which is a deployer name', (done) ->
    process.chdir('../')

    new cmd.default(['s3']).run (err, res) ->
      should.not.exist(err)
      done()

  it 'should error when 1 arg, path does not exist', (done) ->
    new cmd.default(['/foo']).run (err, res) ->
      err.should.match /specified a path to a folder/
      done()

  it 'should error when 1 arg, no ship.conf at path', (done) ->
    new cmd.default(['no_ship_conf']).run (err, res) ->
      err.should.match /specify a deployer/
      done()

  it 'should succeed when 1 arg, ship.conf at path w/ multiple deployers', (done) ->
    new cmd.default(['multiple_deployers']).run (err, res) ->
      should.not.exist(err)
      done()

  it 'should succeed when 1 arg, ship.conf at path w/ one deployer', (done) ->
    new cmd.default(['one_deployer']).run (err, res) ->
      should.not.exist(err)
      done()

  it 'should error when 2 args, path from 1st arg does not exist', (done) ->
    new cmd.default(['/foo', 's3']).run (err, res) ->
      err.should.match /specified a path to a folder/
      done()

  it 'should error when 2 args, deployer name from 2nd arg not found', (done) ->
    new cmd.default(['one_deployer', 'foo']).run (err, res) ->
      err.should.match /deployer in stock/
      done()

  it 'should be able to find ship.conf files for different environments', (done) ->
    new cmd.default(['staging_env'], 'staging').run (err, res) ->
      should.not.exist(err)
      done()    
