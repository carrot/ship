W = require 'when'
fn = require 'when/function'
run = require('child_process').exec
fs = require 'fs'
path = require 'path'
Deployer = require '../deployer'

class Heroku extends Deployer

  constructor: (@path) ->
    super
    @name = 'Heroku'
    @slug = 'heroku'

    # optional config:
    # - name: name of the app on heroku

    @errors =
      git_not_installed: "Git not installed - check out http://git-scm.com to install"
      toolbelt_not_installed: "Heroku toolbelt not installed - check out https://toolbelt.heroku.com to install"
      git_not_initialized: "Git must be initialized in order to deploy to heroku. \nFor help getting started with git, check out http://try.github.io/levels/1/challenges/1"
      not_authenticated: "You are not logged in to heroku, try `heroku login`"
      commit_not_made: "You have to make at least one commit to deploy"
      changes_not_committed: "Commit your changes before deploying"

  configure: (data, cb) ->
    super(@slug, data)
    cb()

  deploy: (cb) ->
    @debug.log "deploying #{@public} to Heroku"

    fn.call(check_install.bind(@))
    .then(check_auth.bind(@))
    .then(sync(add_config_files.bind(@)))
    .then(sync(create_project.bind(@)))
    .then(sync(push_code.bind(@)))
    .otherwise(cb)
    .then((res) -> cb(null, res))

  check_install = ->
    if not which('git') then throw @errors.git_not_installed
    if not which('heroku') then throw @errors.toolbelt_not_installed
    if not fs.existsSync(path.join(@public, '.git')) then throw @errors.git_not_initialized
    if execute_in_dir(@public, "git rev-list HEAD --count").match(/fatal/) then throw @errors.commit_not_made
    if execute_in_dir(@public, "git diff HEAD") != '' then throw @errors.changes_not_committed

  check_auth = ->
    deferred = W.defer()

    run 'heroku auth:whoami', { timeout: 5000 }, (err, out) ->
      if err then return referred.reject(@errors.not_authenticated)
      deferred.resolve()

    return deferred.promise

  add_config_files = ->
    if not fs.existsSync(path.join(@public, 'Procfile'))
      src = path.join(__dirname, 'config', '/*')
      cp('-rf', src, @public)
      # TODO: make a commit here

  create_project = ->
    if execute_in_dir(@public, "git branch -r | grep heroku") then return
    @debug.log 'creating app on heroku...'.grey
    execute_in_dir @public, "heroku create #{@config.name || ''}"

  push_code = ->
    @debug.log 'pushing to heroku (this may take a minute)...'.grey
    out = execute_in_dir @public, "git push heroku master"
    if out.match(/up-to-date/) then return "Heroku: ".bold + "#{out}"
    url = out.match(/(http:\/\/.*\.herokuapp\.com)/)[1]
    "Heroku: ".bold + "your site is live at #{url}"

  # 
  # @api private
  # 
  
  sync = (func) -> fn.lift(func)

  execute_in_dir = (dir, cmd) ->
    cmd = exec("cd #{dir}; #{cmd}", {silent: true})
    if (cmd.code > 0)
      console.log cmd.output
      return false
    return cmd.output

module.exports = Heroku
