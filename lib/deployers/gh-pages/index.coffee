path = require 'path'
fs = require 'fs'
shell = require 'shelljs/global'
readdirp = require 'readdirp'
W = require 'when'

Deployer = require '../deployer'

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
        required: true
        default: 'gh-pages'

  runDeploy: (config) ->
    @checkInstallStatus()
    originalBranch = @getOrigionalBranch()
    @checkForUncommittedChanges()
    @switchToDeployBranch(config.branch)
    @removeSourceFiles(config.target)
      .then( => @dumpTargetToRoot(config.target, config.projectRoot))
      .then( => @makeCommit())
      .then( => @pushCode(config.branch, originalBranch))

  checkInstallStatus: ->
    if not which('git')
      throw new Error(@_errors.NOT_INSTALLED)

    #TODO: make remote name configurable
    if not execute('git remote | grep origin')
      throw new Error(@_errors.REMOTE_ORIGIN)

  getOrigionalBranch: ->
    originalBranch = execute('git rev-parse --abbrev-ref HEAD')
    if not originalBranch then throw new Error(@_errors.MAKE_COMMIT)

    console.log "starting on branch #{originalBranch}"
    return originalBranch

  checkForUncommittedChanges: ->
    unless exec('git diff --quiet').code is 0 and exec('git diff --cached --quiet').code is 0
      throw new Error('you have uncommitted changes - you need to commit those before you can deploy')

  switchToDeployBranch: (branch) ->
    console.log "switching to #{branch} branch"

    # remove & recreate branch if it already exists
    if not execute("git branch | grep #{branch}")
      execute("git branch -D #{branch}")
    execute("git branch #{branch}")

    execute("git checkout #{branch}")

  removeSourceFiles: (target) ->
    deferred = W.defer()
    console.log 'removing source files'
    opts =
      root: ''
      directoryFilter: ["!#{target}", '!.git']

    readdirp opts, (err, res) ->
      if err then return deferred.reject(err)
      rm(f.path) for f in res.files
      rm('-rf', d.path) for d in res.directories
      deferred.resolve()

    return deferred.promise

  dumpTargetToRoot: (target, root) ->
    if target is @path then return
    target = path.join(target, '*')
    mv '-f', path.resolve(target), root
    rm '-rf', target

  makeCommit: ->
    console.log 'committing to git'
    execute 'git add .'
    execute 'git commit -am "deploy to github pages"'

  pushCode: (branch, originalBranch) ->
    console.log "pushing to origin/#{branch}"
    execute "git push origin #{branch} --force"
    console.log "switching back to #{originalBranch} branch"
    execute "git checkout #{originalBranch}"
    console.log 'deployed to github pages'

###*
 * @param {String} input The command to execute
 * @return {String|Boolean} `false` if there was a non-zero exit code, or the
   output of the command in a string if it succeeded
###
execute = (input) ->
  cmd = exec(input, silent: true)
  if cmd.code > 0 or cmd.output is '' then false else cmd.output.trim()

module.exports = Github
