W = require 'when'
fn = require 'when/function'
run = require('child_process').exec
fs = require 'fs'
semver = require 'semver'

Deployer = require '../../deployer'

class Nodejitsu extends Deployer

  constructor: (@path) ->
    super
    @name = 'Nodejitsu'
    @config =
      target: null
      name: null

    @errors =
      not_installed: "You need to install nodejitsu, try `npm install jitsu -g`"
      not_logged_in: "You are not logged in to nodejitsu, try `jitsu login`"

  deploy: (cb) ->
    console.log "deploying #{@path} to Nodejitsu"

    fn.call(check_install.bind(@))
    .then(check_credentials.bind(@))
    .then(sync(add_config_files, @))
    .then(sync(push_code, @))
    .otherwise((err) -> console.error(err))
    .ensure(cb)

  check_install = ->
    if not which('jitsu') then throw @errors.not_installed

  check_credentials = ->
    deferred = W.defer()

    run 'jitsu list', { timeout: 5000 }, (err, out) ->
      if err then return deferred.reject(@errors.not_logged_in)
      deferred.resolve()

    return deferred.promise

  add_config_files = ->
    # if package.json is present, you're set
    if fs.existsSync(path.join(@public, 'package.json')) then return

    # if not, let's get a template in there
    source = path.join(__dirname, 'template.json')
    cp '-rf', source, @path
    pkg = require(path.join(@path, 'package.json'))

    pkg.name = if @config.name == '' then path.basename(@path) else @config.name
    pkg.subdomain = pkg.name
    fs.writeFileSync(path.join(@path, 'package.json'), JSON.stringify(pkg))

  push_code = ->
    # bump version
    pkg = require(path.join(@path, 'package.json'))
    pkg.version = semver.inc(pkg.version, 'build')
    fs.writeFileSync(path.join(@path, 'package.json'), JSON.stringify(pkg))

    cmd = exec 'jitsu deploy'
    if cmd.code > 0 then throw cmd.output

  #
  # @api private
  #

  sync = (func, ctx) ->
    fn.lift(func.bind(@))

module.exports = Nodejitsu
