W = require 'when'
fn = require 'when/function'
run = require('child_process').exec
require 'shelljs/global'
fs = require 'fs'
path = require 'path'

Deployer = require '../../deployer'
helper = require '../helper'

class Heroku extends Deployer
  ###*
   * Error strings
   * @type {Object<string, string>}
   * @todo Refactor into real exception types
   * @const
  ###
  _errors =
    TOOLBELT_NOT_INSTALLED: 'Heroku toolbelt not installed -
    check out https://toolbelt.heroku.com to install'
    NOT_AUTHENTICATED: 'You are not logged in to heroku. Try `heroku login`.'

  constructor: ->
    super()
    @configSchema.schema.name =
      type: 'string'
      required: true
    @configSchema.schema.delete =
      type: 'boolean'
      required: true
      default: false
      description: 'Rather than deploying, delete the Heroku app.'

  deploy: (config) ->
    super(config)
    if @_config.delete
      @destroy()
      return
    console.log "deploying #{@_config.name} to Heroku"
    @checkInstall()
    @checkAuth().then( =>
      @addConfigFiles()
      @createProject()
      @pushCode()
    )

  destroy: ->
    console.log 'deleting Heroku app...'
    helper.execute 'git branch -D heroku'

    name = @_config.name
    helper.execute "heroku apps:destroy -a #{name} --confirm #{name}"

  checkInstall: ->
    helper.checkGitRepo()
    if not which('heroku') then throw @_errors.TOOLBELT_NOT_INSTALLED

  checkAuth: ->
    deferred = W.defer()
    run 'heroku auth:whoami', timeout: 5000, (err, out) ->
      if err then return referred.reject(@_errors.NOT_AUTHENTICATED)
      deferred.resolve()
    return deferred.promise

  addConfigFiles: ->
    if not fs.existsSync('Procfile')
      console.log 'No Procfile was found. Adding default configuration.'
      defaultConfig = path.join(__dirname, 'config/*')
      cp(defaultConfig, './')

      err = "Please review the added config files, commit them, and rerun ship"
      throw new Error(err)

  createProject: ->
    if helper.execute 'git remote | grep heroku' then return
    console.log 'creating app on heroku...'
    helper.execute "heroku create #{@_config.name}"

  pushCode: ->
    console.log 'pushing to heroku (this may take a minute)...'
    out = helper.execute 'git push heroku master'
    if /up-to-date/.test out then return 'Heroku: '.bold + "#{out}"
    url = out.match(/(http:\/\/.*\.herokuapp\.com)/)[1]
    console.log 'Heroku: '.bold + "your site is live at #{url}"

module.exports = Heroku
