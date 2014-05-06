path = require 'path'
fs = require 'fs'
shell = require 'shelljs/global'
touch = require('touch').sync #TODO: github.com/arturadib/shelljs/issues/122
readdirp = require 'readdirp'
W = require 'when'

Deployer = require '../../deployer'

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
    UNCOMMITTED_CHANGES: 'You have uncommitted changes - you need to commit those before you can deploy'
    STARTING_ON_WRONG_BRANCH: 'You have the branch that you\'re trying to deploy to checked out right now. Switch branches.'

  constructor: ->
    super()
    @configSchema.schema.branch =
      type: 'string'
      required: true
      default: 'gh-pages'
    @configSchema.schema.nojekyll =
      type: 'boolean'
      required: true
      default: false
      description: 'add a `.nojekyll` file to bypass Jekyll processing'

  deploy: (config) ->
    super(config)
    @checkInstallStatus()
    originalBranch = @getOrigionalBranch()
    @checkForUncommittedChanges()
    @switchToDeployBranch(config.branch, originalBranch)
    @dumpSourceDirToRoot(config.sourceDir, config.projectRoot).then( =>
      @nojekyllOption(config.nojekyll, config.projectRoot)
      @makeCommit()
      @pushCode(config.branch, originalBranch)
    )

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
      throw new Error(@_errors.UNCOMMITTED_CHANGES)

  switchToDeployBranch: (deployBranch, originalBranch) ->
    if originalBranch is deployBranch
      throw new Error(@_errors.STARTING_ON_WRONG_BRANCH)
    console.log "switching to #{deployBranch} branch"

    # remove & recreate branch if it already exists
    if execute("git branch | grep #{deployBranch}")
      console.log "removing #{deployBranch} branch"
      execute("git branch -D #{deployBranch}")
    execute("git branch #{deployBranch}")

    execute("git checkout #{deployBranch}")

  ###*
   * Check for and parse the .gitignore file. This is needed because we can't
     get git-ignored files back when we switch to the origional branch.
   * @param {String} root
   * @return {Array} Array of strings to be ignored
  ###
  parseGitignore: (root) ->
    gitignoreFile = ''
    try
      gitignoreFile = fs.readFileSync(path.join(root, '.gitignore'), 'utf8')
    ignore = []
    gitignoreFile
      .split('\n')
      .filter((v) -> v.length)
      .forEach((v) -> ignore.push v)
    return ignore

  dumpSourceDirToRoot: (sourceDir, root) ->
    # remove extraneous files
    deferred = W.defer()
    console.log 'removing extraneous files'
    ignored = gitignored = @parseGitignore(root)
    ignored.push sourceDir, '.git', '.gitignore'
    ignored = ignored.map (v) -> "!#{v}"
    opts = root: root, fileFilter: ignored, directoryFilter: ignored
    readdirp opts, (err, res) ->
      if err then return deferred.reject(err)
      rm(f.path) for f in res.files
      rm('-rf', d.path) for d in res.directories
      # dump source dir to root
      if sourceDir is root then return deferred.resolve()
      cp '-rf', path.resolve(path.join(sourceDir, '*')), root
      if sourceDir not in gitignored
        # we don't need to remove it if it's going to be ignored when we
        # commit
        rm '-rf', sourceDir
      deferred.resolve()
    return deferred.promise

  nojekyllOption: (makeNojekyllFile, root) ->
    if makeNojekyllFile then touch path.join(root, '.nojekyll')

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
