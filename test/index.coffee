path   = require 'path'
fs     = require 'fs'
yaml   = require 'js-yaml'
nodefn = require 'when/node'

describe 'api', ->

  describe 'constructor', ->

    it 'should construct a new ship instance', ->
      (-> new Ship(root: __dirname, deployer: 's3')).should.not.throw()

    it 'should error if passed an invalid deployer', ->
      (-> new Ship(root: __dirname, deployer: 'wow'))
        .should.throw('wow is not a valid deployer')

    it 'should error if passed a nonexistant path to deploy', ->
      (-> new Ship(root: 'wow', deployer: 's3')).should.throw()

    it 'should correctly format the shipfile with an environment passed', ->
      project = new Ship(root: __dirname, deployer: 'nowhere', env: 'staging')
      path.basename(project.shipfile).should.equal('ship.staging.conf')

    it 'should find the shipfile in a custom conf directory', ->
      p         = path.join(_path, 'api', 'custom_conf_path')
      conf_path = path.join(p, 'conf')
      project = new Ship(root: p, deployer: 'nowhere', conf: conf_path)
      project.shipfile.should.equal(path.join(conf_path, 'ship.conf'))

    it 'should look for a shipfile in cwd if not present in root', ->
      cwd      = process.cwd()
      test_cwd = path.join(_path, 'api', 'cwd')
      dir      = path.join(test_cwd, 'no_ship_conf')

      process.chdir(test_cwd)
      project = new Ship(root: dir, deployer: 'nowhere')
      project.shipfile.should.equal(path.join(test_cwd, 'ship.conf'))
      process.chdir(cwd)

  describe 'is_configured', ->

    it 'should not be configured if no @config or shipfile', ->
      project = new Ship(root: __dirname, deployer: 's3')
      project.is_configured().should.be.false

    it 'should be configured if @config is defined', ->
      project = new Ship(root: __dirname, deployer: 's3')
      project.config = {}
      project.is_configured().should.be.true

    it 'should be configured if a shipfile is present at root', ->
      dir = path.join(_path, 'api/one_deployer')
      project = new Ship(root: dir, deployer: 's3')
      project.is_configured().should.be.true

  describe 'configure', ->

    it 'should correctly configure a deployer with passed in data', ->
      project = new Ship(root: __dirname, deployer: 's3')
      (-> project.configure(access_key: 1234, secret_key: 1234)).should.not.throw()
      project.config.should.deep.equal(access_key: 1234, secret_key: 1234)

    it 'should error if passed in data does not match requirements', ->
      project = new Ship(root: __dirname, deployer: 's3')
      (-> project.configure(wow: 1234, secret_key: 1234))
        .should.throw('you must specify these keys: access_key secret_key')
      should.not.exist(project.config)

    it 'should not error if the deployer has no config requirements'

  describe 'config_prompt', ->

    it 'should prompt the user to enter config info via command line', ->
      project = new Ship(root: __dirname, deployer: 's3')
      project.config_prompt()
        .progress (prompt) ->
          prompt.rl.emit("line", "1")
          prompt.rl.emit("line", "2")
        .tap (res) -> res.should.deep.equal(access_key: '1', secret_key: '2')
        .tap -> project.config.should.deep.equal(access_key: '1', secret_key: '2')
        .should.be.fulfilled

    it 'should not activate the prompt if deployer has no config requirements'

  describe 'write_config', ->

    it 'should write a shipfile with the config info to the cwd', ->
      project = new Ship(root: __dirname, deployer: 's3')
      project.configure(access_key: 'foo', secret_key: 'bar')
      shipfile = path.join(process.cwd(), 'ship.conf')

      project.write_config()
        .then(nodefn.lift(fs.readFile, shipfile, 'utf8'))
        .then(yaml.safeLoad)
        .tap (res) ->
          res.s3.access_key.should.equal('foo')
          res.s3.secret_key.should.equal('bar')
        .then(-> fs.unlinkSync(shipfile))
        .should.be.fulfilled

    it 'should write to an alternate path if an override is provided', ->
      project = new Ship(root: __dirname, deployer: 's3')
      project.configure(access_key: 'foo', secret_key: 'bar')
      shipfile = path.join(__dirname, '../ship.conf')

      project.write_config(shipfile)
        .then(nodefn.lift(fs.readFile, shipfile, 'utf8'))
        .then(yaml.safeLoad)
        .tap (res) ->
          res.s3.access_key.should.equal('foo')
          res.s3.secret_key.should.equal('bar')
        .then(-> fs.unlinkSync(shipfile))
        .should.be.fulfilled

    it 'should error if instance has not been configured', ->
      project = new Ship(root: __dirname, deployer: 's3')
      project.write_config()
        .should.be.rejectedWith('deployer has not yet been configured')

  describe 'deploy', ->

    it 'should load in root/shipfile.conf as config if present', ->
      dir = path.join(_path, 'api/one_deployer')
      project = new Ship(root: dir, deployer: 'nowhere')
      project.deploy()
        .tap -> project.config.should.deep.equal(nothing: 'wow')
        .should.be.fulfilled

    it 'should just deploy if already configured', ->
      project = new Ship(root: __dirname, deployer: 'nowhere')
      project.configure(nothing: 'foo')
      project.deploy().should.be.fulfilled

    it 'should error if not configured and no shipfile present', ->
      project = new Ship(root: __dirname, deployer: 'nowhere')
      project.deploy()
        .should.be.rejectedWith('you must configure the deployer')

    it "should error if shipfile keys don't match the deployer's", ->
      dir = path.join(_path, 'api/incorrect_config')
      project = new Ship(root: dir, deployer: 'nowhere')
      project.deploy()
        .should.be.rejectedWith('you must specify these keys: nothing')

    it 'should use the correct shipfile given an environment', ->
      dir = path.join(_path, 'api/staging_env')
      project = new Ship(root: dir, deployer: 'nowhere', env: 'staging')
      project.deploy().should.be.fulfilled

    it 'should not error if not configured and deployer has no config requirements'
