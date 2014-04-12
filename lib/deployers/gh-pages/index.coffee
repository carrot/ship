require 'colors'
Deployer = require '../deployer'
path = require 'path'
fs = require 'fs'
shell = require 'shelljs/global'
readdirp = require 'readdirp'
W = require 'when'

class Github extends Deployer
  ###*
   * Error strings
   * @type {Object<string, string>}
   * @todo Refactor into real exception types
   * @const
  ###
  _errors:
    NOT_INSTALLED: 'You must install git - see http://git-scm.com'
    REMOTE_ORIGIN: 'Make sure you have a remote origin branch for github'
    MAKE_COMMIT: 'You need to make a commit before deploying'

  constructor: ->
    @config.schema =
      branch:
        type: 'string'
        default: 'gh-pages'

  deploy: (path, config) ->
    super(path, config)
    checkInstallStatus()
    checkForUncommittedChanges()
    switchToDeployBranch()
    removeSourceFiles()
      .then(-> dumpPublicToRoot())
      .then(-> pushCode())

  checkInstallStatus: ->
    if not which('git')
      throw new Error(@_errors.NOT_INSTALLED)

    #TODO: make remote name configurable
    if not execute('git remote | grep origin')
      throw new Error(@_errors.REMOTE_ORIGIN)

    @originalBranch = execute('git rev-parse --abbrev-ref HEAD')
    if not @originalBranch then throw new Error(@_errors.MAKE_COMMIT)

    console.log "starting on branch #{originalBranch}"

  checkForUncommittedChanges: ->
    if not execute('git diff --quiet && git diff --cached --quiet')
      throw new Error('you have uncommitted changes - you need to commit those before you can deploy')

  switchToDeployBranch: ->
    console.log "switching to #{@config.data.branch} branch"

    if not execute("git branch | grep #{@config.data.branch}")
      execute("git branch -D #{@config.data.branch}")

    execute("git branch #{@config.data.branch}")
    execute("git checkout #{@config.data.branch}")

  removeSourceFiles: ->
    deferred = W.defer()
    console.log 'removing source files'
    opts =
      root: ''
      directoryFilter: ["!#{@public}", '!.git']

    readdirp opts, (err, res) ->
      if err then return deferred.reject(err)
      rm(f.path) for f in res.files
      rm('-rf', d.path) for d in res.directories
      deferred.resolve()

    return deferred.promise

  dumpPublicToRoot: ->
    if @public is @path then return

    target = path.join(@public, '*')
    execute("mv -f #{path.resolve(target)} #{@path}")
    rm '-rf', @public

  pushCode: ->
    console.log 'pushing to origin/#{@config.data.branch}'
    execute "git push origin #{@config.data.branch} --force"
    console.log "switching back to #{@originalBranch} branch"
    execute "git checkout #{@originalBranch}"
    console.log 'deployed to github pages'

###*
 * @param  {[type]} input [description]
 * @return {[type]}       [description]
###
execute = (input) ->
  cmd = exec(input, silent: true)
  if cmd.code > 0 or cmd.output is '' then false else cmd.output.trim()

module.exports = Github
