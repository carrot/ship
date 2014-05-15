path = require 'path'
fs = require 'fs'
require 'shelljs/global'
touch = require('touch').sync #TODO: github.com/arturadib/shelljs/issues/122
W = require 'when'

Deployer = require '../../deployer'
helper = require '../helper'

class Github extends Deployer
  ###*
   * Error strings
   * @type {Object<string, string>}
   * @todo Refactor into real exception types
   * @const
  ###
  _errors:
    REMOTE_ORIGIN: 'Make sure you have a remote origin branch for github'
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
    helper.checkGitRepo()
    @checkGitRemote()
    @_config.originalBranch = @getOrigionalBranch()
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

  checkGitRemote: ->
    # TODO: make remote name configurable
    if not helper.execute('git remote | grep origin')
      throw new Error(@_errors.REMOTE_ORIGIN)

  getOrigionalBranch: ->
    originalBranch = helper.execute('git rev-parse --abbrev-ref HEAD')
    if not originalBranch then throw new Error(@_errors.MAKE_COMMIT)

    console.log "starting on branch #{originalBranch}"
    return originalBranch

  switchToDeployBranch: ->
    if @_config.originalBranch is @_config.branch
      throw new Error(@_errors.STARTING_ON_WRONG_BRANCH)

    # remove & recreate branch if it already exists
    if helper.execute("git branch | grep #{@_config.branch}")
      console.log "removing #{@_config.branch} branch"
      helper.execute("git branch -D #{@_config.branch}")
    helper.execute("git branch #{@_config.branch}")
    @switchBranch(@_config.branch)

  switchBranch: (branch) ->
    helper.execute "git checkout #{branch}", false

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
    helper.execute 'git add .'
    helper.execute 'git commit -am "deploy to github pages"'

  pushCode: ->
    console.log "pushing to origin/#{@_config.branch}"
    helper.execute "git push origin #{@_config.branch} --force", false

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

module.exports = Github
