path      = require 'path'
fs        = require 'fs'
W         = require 'when'
nodefn    = require 'when/node'
guard     = require 'when/guard'
keys      = require 'when/keys'
_         = require 'lodash'
readdirp  = require 'readdirp'
GithubApi = require 'github'
minimatch = require 'minimatch'
file_map  = require 'file-map'

module.exports = (root, config) ->
  d = W.defer()

  config.ignore = _.compact([
    '.gitignore',
    '.git{/**,}',
    '**/node_modules{/**,}'].concat(config.ignore))
  repo_user = config.repo.split('/')[0]
  repo_name = config.repo.split('/')[1]

  gh = new GithubApi(version: "3.0.0", debug: false)
  ctx = { root: root, gh: gh, config: config, user: repo_user, repo: repo_name }

  authenticate.call(ctx).with(ctx)
    .then(get_latest_gh_pages_commit)
    .then(build_tree)
    .then(create_commit)
    .then(update_gh_pages_branch)
    .done ->
      d.resolve
        deployer: 'gh-pages'
        url: "http://#{repo_user}.github.io/#{repo_name}"
        destroy: destroy.bind(@)
    , d.reject

  return d.promise

module.exports.config =
  required: ['username', 'password', 'repo']
  optional: ['ignore']

###*
 * Authenticates with github using the provided credentials
 * @return {Promise} - completed authentication, if incorrect, errors come later
###

authenticate = ->
  @gh.authenticate
    type: 'basic'
    username: @config.username
    password: @config.password
  W.resolve()

###*
 * Grabs the latest commit from the github pages branch. If this doesn't exist,
 * creates the branch with a commit for a basic readme.
 *
 * @return {Promise} a promise for the sha of the latest commit
###

get_latest_gh_pages_commit = ->
  nodefn.call @gh.repos.getCommits,
    user: @user
    repo: @repo
    sha: 'gh-pages'
  .then (res) -> res[0].sha
  .catch (err) =>
    msg = JSON.parse(err.message).message
    if msg == 'Git Repository is empty.' then create_initial_commit.call(@)
    if msg == 'Not Found' then create_branch.call(@)

###*
 * If a repo is empty, a commit needs to be created before trees can be pushed.
 * This method creates
 * @return {Promise} a promise for the sha of the newly created commit
###

create_initial_commit = ->
  nodefn.call @gh.repos.createFile,
    user: @user
    repo: @repo
    branch: 'gh-pages'
    message: 'initial commit'
    path: 'README.md'
    content: new Buffer("#{@user}/#{@repo}").toString('base64')
  .then (res) -> res.sha

create_branch = ->
  get_default_branch.call(@).then (branch) =>
    nodefn.call @gh.gitdata.createReference,
      user: @user
      repo: @repo
      ref: 'refs/heads/gh-pages'
      sha: branch.commit.sha

get_default_branch = ->
  nodefn.call @gh.repos.getBranches,
    user: @user
    repo: @repo
  .then (res) -> res[0]

###*
 * Runs through the root and recrusively builds up the structure in the format
 * that github needs it. Creates blobs for files and trees at every folder
 * level, nesting them inside each other and returning a single tree object with
 * SHA's from github, ready to be committed.
 *
 * @return {Object} github-formatted tree object
###

build_tree = ->
  i = @config.ignore
  file_map(@root, { file_ignores: i, directory_ignores: i })
    .then (tree) => format_tree.call(@, path: '', children: tree)

###*
 * This is the real workhorse. This method recurses through a given directory,
 * grabbing the files and folders and creating blobs and trees, nested properly,
 * through github's API.
 *
 * @param  {Object} root - a directory object provided by file-map
 * @return {Promise} a promise for a github-formatted tree object
###

format_tree = (root) ->
  dirs = _.where(root.children, { type: 'directory' })
  files = _.where(root.children, { type: 'file' })

  if dirs.length
    W.map(dirs, format_tree.bind(@))
      .then (dir_objects) =>
        W.map(files, create_blob.bind(@))
        .then (file_objects) -> dir_objects.concat(file_objects)
      .then(create_tree.bind(@, root))
  else
    W.map(files, create_blob.bind(@))
      .then(create_tree.bind(@, root))

###*
 * Creates a blob through github's API, given a file.
 *
 * @param  {Object} file - file object via file-map
 * @return {Promise} promise for a github-formatted file object with the sha
###

create_blob = (file) ->
  nodefn.call(fs.readFile, file.full_path)
  .then(get_blob_sha.bind(@))
  .then (sha) ->
    path: path.basename(file.path)
    mode: '100644'
    type: 'blob'
    sha: sha

###*
 * Creates a tree through github's API, given an array of contents.
 *
 * @param {Object} root - directory object via file-map of the tree's root dir
 * @param  {Array} tree - array of github-formatted tree and/or blob objects
 * @return {Promise} promise for a github-formatted tree object with the sha
###

create_tree = (root, tree) ->
  get_tree_sha.call(@, tree)
  .then (sha) ->
    path: path.basename(root.path)
    mode: '040000'
    type: 'tree'
    sha: sha

###*
 * Given a file's content, creates a blob through github and returns the sha.
 *
 * @param  {String} content - the content of a file, as a utf8 string
 * @return {Promise} promise for a string representing the blob's sha
###

get_blob_sha = (content) ->
  nodefn.call @gh.gitdata.createBlob.bind(@gh),
    user: @user
    repo: @repo
    content: content.toString('base64')
    encoding: 'base64'
  .then (res) -> res.sha

###*
 * Given a tree array, creates a tree through github and returns the sha.
 *
 * @param  {Array} tree - array containing tree and/or blob objects
 * @return {Promise} promise for a string representing the tree's sha
###

get_tree_sha = (tree) ->
  nodefn.call @gh.gitdata.createTree.bind(@gh),
    user: @user
    repo: @repo
    tree: tree
  .then (res) -> res.sha

###*
 * Given a tree, creates a new commit pointing to that tree.
 *
 * @param  {Object} tree - github-formatted tree object
 * @return {Promise} promise for github api's response to creating the commit
###

create_commit = (tree) ->
  get_latest_gh_pages_commit.call(@)
    .then (sha) => nodefn.call @gh.gitdata.createCommit,
      user: @user
      repo: @repo
      parents: [sha]
      tree: tree.sha
      message: "deploy from ship"

###*
 * Points the gh-pages branch's HEAD to the sha of a given commit.
 *
 * @param  {Object} commit - github api representation of a commit
 * @return {Promise} promise for the github api's response to updating the ref
###

update_gh_pages_branch = (commit) ->
  nodefn.call @gh.gitdata.updateReference,
    user: @user
    repo: @repo
    ref: 'heads/gh-pages'
    sha: commit.sha
    force: true

###*
 * Removes the gh-pages branch, undoing the deploy.
###

destroy = ->
  nodefn.call @gh.gitdata.deleteReference,
    user: @user
    repo: @repo
    ref: 'heads/gh-pages'
