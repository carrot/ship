W = require 'when'
run = require('child_process').exec
fs = require 'fs'
semver = require 'semver'

class Nodejitsu

  constructor: (@path) ->
    @name = 'Nodejitsu'
    @config =
      target: null
      name: null

    @errors = 
      not_installed: "You need to install nodejitsu first, try `npm install jitsu -g`"
      not_logged_in: "You are not logged in to nodejitsu, try `jitsu login`"

  deploy: (cb) ->
    console.log "deploying #{@path} to Nodejitsu"

    check_install.call(@)
    .then(check_credentials.bind(@))
    .then(add_config_files.bind(@))
    .then(push_code.bind(@))
    .otherwise((err) -> console.error(err))
    .ensure(cb)

  check_install = ->
    deferred = W.defer()
    if not which('jitsu') then return deferred.reject(@errors.not_installed)
    deferred.resolve()

  check_credentials = ->
    deferred = W.defer()
    run 'jitsu list', { timeout: 5000 }, (err, out) ->
      if err then return deferred.reject(@errors.not_logged_in)
      deferred.resolve()

  add_config_files = ->
    deferred = W.defer()

    # if package.json is present, you're set
    if fs.existsSync(path.join(@public, 'package.json')) then return deferred.resolve()

    # if not, let's get a template in there
    source = path.join(__dirname, 'template.json')
    cp '-rf', source, @path
    pkg = require(path.join(@path, 'package.json'))

    pkg.name = if @config.name == '' then path.basename(@path) else @config.name
    pkg.subdomain = pkg.name
    fs.writeFileSync(path.join(@path, 'package.json'), JSON.stringify(pkg))
    deferred.resolve()

  push_code = ->
    deferred = W.defer()

    # bump version
    pkg = require(path.join(@path, 'package.json'))
    pkg.version = semver.inc(pkg.version, 'build')
    fs.writeFileSync(path.join(@path, 'package.json'), JSON.stringify(pkg))

    cmd = exec 'jitsu deploy'
    if cmd.code > 0 then return deferred.reject(cmd.output)
    deferred.resolve()

module.exports = Nodejitsu
