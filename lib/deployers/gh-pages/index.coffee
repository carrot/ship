path = require 'path'
fs = require 'fs'
shell = require 'shelljs/global'
touch = require('touch').sync #TODO: github.com/arturadib/shelljs/issues/122
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
    @_config.originalBranch = @getOrigionalBranch()
    @checkForUncommittedChanges()
    @switchToDeployBranch()
    @dumpSourceDirToRoot().then( =>
      if @_config.nojekyll
        @makeNojekyllFile()
      @makeCommit()
      @pushCode()
      @switchBranch(@_config.originalBranch)
      @cleanup()
      console.log 'deployed to github pages'
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

  switchToDeployBranch: ->
    if @_config.originalBranch is @_config.branch
      throw new Error(@_errors.STARTING_ON_WRONG_BRANCH)

    # remove & recreate branch if it already exists
    if execute("git branch | grep #{@_config.branch}")
      console.log "removing #{@_config.branch} branch"
      execute("git branch -D #{@_config.branch}")
    execute("git branch #{@_config.branch}")
    @switchBranch(@_config.branch)

  switchBranch: (branch) ->
    execute "git checkout #{branch}", false

  dumpSourceDirToRoot: ->
    deferred = W.defer()
    @getFileList((err, res) =>
      if err then return deferred.reject err
      files = fs.readdirSync(@_config.projectRoot)
      @_config.tmpDir = path.join @_config.projectRoot, 'ship-tmp'
      console.log "moving everything into #{@_config.tmpDir}"
      mkdir @_config.tmpDir
      for file in files
        if file in ['.git', @_config.tmpDir] then continue
        file = path.join @_config.projectRoot, file
        console.log "#{file} -> #{@_config.tmpDir}"
        mv '-f', file, @_config.tmpDir

      console.log 'copying files to be deployed into the project root'
      for file in res.files
        file = path.join @_config.sourceDir, file.path
        from = path.join @_config.tmpDir, file
        to = path.relative(@_config.sourceDir, file)
        console.log "#{from} -> #{to}"
        mkdir '-p', path.dirname(to) # make sure the dest exists
        cp '-f', from, to

      # append/make a .gitignore to prevent the tmp files from being committed
      fs.appendFileSync(
        path.join(@_config.projectRoot, '.gitignore')
        @_config.tmpDir
      )
      deferred.resolve()
    )
    return deferred.promise

  makeNojekyllFile: ->
    touch path.join(@_config.projectRoot, '.nojekyll')

  makeCommit: ->
    console.log 'committing to git'
    execute 'git add .'
    execute 'git commit -am "deploy to github pages"'

  pushCode: ->
    console.log "pushing to origin/#{@_config.branch}"
    execute "git push origin #{@_config.branch} --force", false

  cleanup: ->
    # remove all the files we dumped to the root
    files = fs.readdirSync(@_config.projectRoot)
    for file in files
      if file in ['.git', @_config.tmpDir] then continue
      file = path.join @_config.projectRoot, file
      rm '-R', file
    # move the tmp files we saved back to root (2nd mv() is for files that
    # start with a `.`) and remove the empty tmp dir
    mv path.join(@_config.tmpDir, '*'), @_config.projectRoot
    mv path.join(@_config.tmpDir, '.*'), @_config.projectRoot
    fs.rmdirSync(@_config.tmpDir)

###*
 * @param {String} input The command to execute
 * @return {String|Boolean} `false` if there was a non-zero exit code, or the
   output of the command in a string if it succeeded
###
execute = (input, silent = true) ->
  cmd = exec(input, silent: silent)
  if cmd.code > 0 or cmd.output is '' then false else cmd.output.trim()

module.exports = Github
