W = require 'when'
fn = require 'when/function'
run = require('child_process').exec
shell = require 'shelljs'
fs = require 'fs'
path = require 'path'

Deployer = require '../../deployer'

class Heroku extends Deployer
  ###*
   * Error strings
   * @type {Object<string, string>}
   * @todo Refactor into real exception types
   * @const
  ###
  _errors =
    GIT_NOT_INSTALLED: 'Git not installed - check out http://git-scm.com to install'
    TOOLBELT_NOT_INSTALLED: 'Heroku toolbelt not installed - check out https://toolbelt.heroku.com to install'
    GIT_NOT_INITIALIZED: 'Git must be initialized in order to deploy to heroku. \nFor help getting started with git, check out http://try.github.io/levels/1/challenges/1'
    NOT_AUTHENTICATED: 'You are not logged in to heroku, try `heroku login`'
    COMMIT_NOT_MADE: 'You have to make at least one commit to deploy'
    CHANGES_NOT_COMMITTED: 'Commit your changes before deploying'

  constructor: ->
    super()
    # name: name of the app on heroku

  deploy: (config) ->
    super(config)
    console.log "deploying #{@payload} to Heroku"

    fn.call(checkInstall)
      .then(checkAuth)
      .then(sync(addConfigFiles))
      .then(sync(createProject))
      .then(sync(pushCode))
      .done(((res) -> cb(null, res)), cb)
      # tap and nab the app name if not already defined

  destroy: (cb) ->
    execute_in_dir(@payload, 'git branch -D heroku')
    execute_in_dir(@payload, 'heroku apps:destroy ship-testing-app --ship-testing-app')

  checkInstall: ->
    if not which('git') then throw @_errors.GIT_NOT_INSTALLED
    if not which('heroku') then throw @_errors.TOOLBELT_NOT_INSTALLED
    if not fs.existsSync(path.join(@payload, '.git'))
      throw @_errors.GIT_NOT_INITIALIZED
    if execute_in_dir(@payload, 'git rev-list HEAD --count').match(/fatal/)
      throw @_errors.COMMIT_NOT_MADE
    if execute_in_dir(@payload, 'git diff HEAD') isnt ''
      throw @_errors.CHANGES_NOT_COMMITTED

  checkAuth: ->
    deferred = W.defer()

    run 'heroku auth:whoami', timeout: 5000, (err, out) ->
      if err then return referred.reject(@_errors.NOT_AUTHENTICATED)
      deferred.resolve()

    return deferred.promise

  addConfigFiles: ->
    if not fs.existsSync(path.join(@payload, 'Procfile'))
      src = path.join(__dirname, 'config', '/*')
      cp('-rf', src, @payload)
      # TODO: make a commit here

  createProject: ->
    if execute_in_dir(@payload, 'git branch -r | grep heroku') then return
    console.log 'creating app on heroku...'.grey
    execute_in_dir @payload, "heroku create #{@config.name or ''}"

  pushCode: ->
    console.log 'pushing to heroku (this may take a minute)...'.grey
    out = execute_in_dir @payload, 'git push heroku master'
    if out.match(/up-to-date/) then return 'Heroku: '.bold + "#{out}"
    url = out.match(/(http:\/\/.*\.herokuapp\.com)/)[1]
    'Heroku: '.bold + "your site is live at #{url}"

  ###*
   * [sync description]
   * @param {[type]} func [description]
   * @return {[type]} [description]
   * @private
  ###
  sync: (func) -> fn.lift(func)

  ###*
   * [execute_in_dir description]
   * @param {[type]} dir [description]
   * @param {[type]} cmd [description]
   * @return {[type]} [description]
   * @private
  ###
  execute_in_dir: (dir, cmd) ->
    cmd = shell.exec("cd #{dir}; #{cmd}", silent: true)
    if (cmd.code > 0)
      console.log cmd.output
      return false
    return cmd.output

module.exports = Heroku
