W       = require 'when'
node    = require 'when/node'
fs      = require 'fs-extra'
path    = require 'path'
{spawn} = require 'child-process-promise'

module.exports = (root, config) ->

  d = W.defer()

  parent_root = path.resolve(root, '..')
  cordova     = path.resolve(__dirname, '../../../node_modules/cordova/bin/cordova')

  ['packageName', 'name'].forEach (prop) ->
    msg = if prop is 'packageName' then "com.company.project" else "ProjectName"
    if not config[prop] then d.reject "#{prop} not specified - example: #{msg}"

  data =
    d               : d
    config          : config
    root            : root
    parent_root     : parent_root
    project_exists  : null
    platform_exists : null
    out             : 'cordova'
    cordova         : cordova

  W().with(data)
    .then checkProjectExistence
    .then createOrUpdateProject
    .then checkPlatformExistence
    .done ->
      d.resolve deployer: 'android'
    , d.reject

  return d.promise

module.exports.config =
  required: ['packageName', 'name']

checkProjectExistence =  ->
  @d.notify "Checking for existing Cordova project..."
  node.call(fs.readFile, path.join(@out, 'config.xml'))
    .then =>
      @project_exists = true; @d.notify "Cordova project found"
    .catch =>
      @project_exists = false; @d.notify "Existing project not found"

createOrUpdateProject = ->
  if @project_exists
    update.call(@)
  else
    create.call(@)

create = ->
  args = ['create', @out, @config.packageName, @config.name]
  spawn @cordova, args, cwd: @parent_root
    .progress (process) =>
      process.stdout.on 'data', (data) => @d.notify(data.toString().trim())
      process.stderr.on 'data', (data) => console.error(data.toString().trim())
    .then copyFiles.bind(@)
    .then => @d.notify "Done creating new Cordova project"

update = ->
  copyFiles.call(@)

copyFiles = ->
  @d.notify "Copying files..."
  www_dir = path.join(@parent_root, @out, 'www')
  removeDir(www_dir)
    .then moveDir.bind(@, @root, www_dir)

removeDir = (dir) ->
  node.call fs.remove, dir

moveDir = (root, dir) ->
  node.call fs.move, root, dir, clobber: true

checkPlatformExistence = ->
  @d.notify "Checking platform existence..."
  node.call(fs.readdir, path.join(@out, 'platforms', 'android'))
    .then =>
      @platform_exists = true; @d.notify "Android platform exists"
    .catch =>
      @platform_exists = false; @d.notify "Android platform not added"
