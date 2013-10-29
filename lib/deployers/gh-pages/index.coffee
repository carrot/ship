require 'colors'
Deployer = require '../deployer'
path = require 'path'
fs = require 'fs'
shell = require 'shelljs/global'
readdirp = require 'readdirp'
W = require 'when'
fn = require 'when/function'

class Github extends Deployer

  constructor: (@path) ->
    super
    @name = 'Github Pages'
    @config =
      target: null

    @errors = 
      not_installed: 'You must install git - see http://git-scm.com'
      remote_origin: 'Make sure you have a remote origin branch for github'
      make_commit: 'You need to make a commit before deploying'

  deploy: (cb) ->
    check_install_status.call(@)
    .then(move_to_gh_pages_branch.bind(@))
    .then(remove_source_files.bind(@))
    .then(dump_public_to_root.bind(@))
    .then(push_code.bind(@))
    .otherwise((err) -> console.error(err))
    .ensure(cb)

  check_install_status = ->
    deferred = W.defer()

    if not which('git')
      return deferred.reject(@error.not_installed)

    if not execute('git remote | grep origin')
      return deferred.reject(@errors.remote_origin)

    @original_branch = execute('git rev-parse --abbrev-ref HEAD') 
    if not @original_branch then return deferred.reject(@errors.make_commit)

    console.log "starting on branch #{original_branch}"
    deferred.resolve()

  move_to_gh_pages_branch = ->
    console.log 'switching to gh-pages branch'.grey

    if not execute('git branch | grep gh-pages')
      execute('git branch -D gh-pages')

    execute('git branch gh-pages')
    execute('git checkout gh-pages')
    fn.call()

  remove_source_files = ->
    deferred = W.defer()
    console.log 'removing source files'.grey

    opts = { root: '', directoryFilter: ["!#{@public}", '!.git'] };

    readdirp opts, (err, res) ->
      if err then return deferred.reject(err)
      rm(f.path) for f in res.files
      rm('-rf', d.path) for d in res.directories
      deferred.resolve()

  dump_public_to_root = ->
    if @public == @path then return fn.call()

    target = path.join(@public, '*')
    execute("mv -f #{path.resolve(target)} #{@path}");
    rm '-rf', @public
    fn.call()

  push_code = ->
    console.log 'pushing to origin/gh-pages'.grey
    execute "git push origin gh-pages --force"

    console.log "switching back to #{@original_branch} branch".grey
    execute "git checkout #{@original_branch}"
 
    console.log 'deployed to github pages'.grey
    fn.call()

  # 
  # @api private
  # 

  execute = (input) ->
    cmd = exec(input, { silent: true });
    if cmd.code > 0 or cmd.output == '' then false else cmd.output.trim()

module.exports = Github
