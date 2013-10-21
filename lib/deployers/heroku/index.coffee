W = require 'when'
fn = require 'when/function'
open = require 'open'
run = require('child_process').exec
fs = require 'fs'

class Heroku

  constructor: (@path) ->
    @name = 'Heroku'
    @config =
      target: null
      name: null

    @errors =
      not_installed: "You need to install heroku first. We'll open the download page for you"
      not_authenticated: "You are not logged in to heroku -- try running `heroku login`"

  deploy: (cb) ->
    console.log "deploying #{@path} to Heroku"

    fn.call(check_install.bind(@))
    .then(check_auth.bind(@))
    .then(sync(add_config_files, @))
    .then(sync(create_project, @))
    .then(sync(push_code, @))
    .otherwise((err) -> console.error(err))
    .ensure(cb)
    cb()

  check_install = ->
    if which('heroku') then return
    setTimeout (-> open('https://toolbelt.heroku.com')), 700
    throw @errors.not_installed

  check_auth = ->
    deferred = W.defer()

    run 'heroku auth:whoami', { timeout: 5000 }, (err, out) ->
      if err then return referred.reject(@errors.not_authenticated)
      deferred.resolve()

    return deferred.promise

  add_config_files = ->
    if not fs.existsSync(path.join(@path, 'Procfile'))
      src = path.join(__dirname, 'config', '/*')
      cp('-rf', src, @path)

  create_project = ->
    if exec('git branch -r | grep heroku').output != '' then return

    console.log 'creating app on heroku...'.grey
    cmd = exec "heroku create #{@config.name || ''}"
    if cmd.code > 0 then throw cmd.output

  push_code = ->
    console.log 'pushing master branch to heroku (this may take a few seconds)...'.grey
    cmd = exec 'git push heroku master'
    if (cmd.code > 0) then throw cmd.output

  # 
  # @api private
  # 
  
  sync = (func, ctx) ->
    fn.lift(func.bind(@))

module.exports = Heroku
