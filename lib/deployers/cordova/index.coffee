W       = require 'when'
node    = require 'when/node'
fs      = require 'fs-extra'
path    = require 'path'
{spawn} = require 'child-process-promise'

module.exports = (root, config) ->

  d = W.defer()

  parent_root = path.resolve(root, '..')
  cordova     = path.resolve(__dirname, '../../../node_modules/cordova/bin/cordova')

  ['packageName', 'name', 'platforms'].forEach (prop) ->
    switch prop
      when 'packageName' then msg = "com.company.project"
      when 'name' then msg = "ProjectName"
      when 'platforms' then msg = "ios android"
    if not config[prop] then d.reject "#{prop} not specified - example: #{msg}"

  data =
    d               : d
    config          : config
    platforms       : config.platforms.split(' ')
    root            : root
    parent_root     : parent_root
    project_exists  : null
    platform_exists : {}
    out             : 'cordova'
    cordova         : cordova

  W().with(data)
    .then check_project_existence
    .then create_or_update_project
    .then check_platform_existence
    .then add_platforms
    .then build_platforms
    .done ->
      d.resolve deployer: 'cordova'
    , d.reject

  return d.promise

module.exports.config =
  required: ['packageName', 'name', 'platforms']

###*
 * [check_project_existence description]
 * @return {[type]} [description]
###
check_project_existence =  ->
  @d.notify "Checking for existing Cordova project..."
  node.call(fs.readFile, path.join(@out, 'config.xml'))
    .then =>
      @project_exists = true; @d.notify "Cordova project found"
    .catch =>
      @project_exists = false; @d.notify "Existing project not found"

###*
 * [create_or_update_project description]
 * @return {[type]} [description]
###
create_or_update_project = ->
  if @project_exists
    update_project.call(@)
  else
    create_project.call(@)

###*
 * [create description]
 * @return {[type]} [description]
###
create_project = ->
  args = ['create', @out, @config.packageName, @config.name]
  spawn @cordova, args, cwd: @parent_root
    .progress (process) =>
      process.stdout.on 'data', (data) => @d.notify(data.toString().trim())
      process.stderr.on 'data', (data) => console.error(data.toString().trim())
    .then copy_files.bind(@)
    .then => @d.notify "Done creating new Cordova project"

###*
 * [update description]
 * @return {[type]} [description]
###
update_project = ->
  copy_files.call(@)

###*
 * [copy_files description]
 * @return {[type]} [description]
###
copy_files = ->
  @d.notify "Copying files..."
  www_dir = path.join(@parent_root, @out, 'www')
  remove_dir(www_dir)
    .then move_dir.bind(@, @root, www_dir)

###*
 * [remove_dir description]
 * @param  {[type]} dir [description]
 * @return {[type]}     [description]
###
remove_dir = (dir) ->
  node.call fs.remove, dir

###*
 * [move_dir description]
 * @param  {[type]} root [description]
 * @param  {[type]} dir  [description]
 * @return {[type]}      [description]
###
move_dir = (root, dir) ->
  node.call fs.move, root, dir, clobber: true

###*
 * [check_platform_existence description]
 * @return {[type]} [description]
###
check_platform_existence = ->
  @d.notify "Checking platform existence..."
  W.map @platforms, (platform) =>
    node.call(fs.readdir, path.join(@out, 'platforms', platform))
      .then =>
        @platform_exists[platform] = true
        @d.notify "#{platform} platform exists"
      .catch =>
        @platform_exists[platform] = false
        @d.notify "#{platform} platform not added"

###*
 * [add__platforms description]
###
add_platforms = ->
  W.map @platforms, (platform) =>
    if not @platform_exists[platform]
      @d.notify "Adding #{platform} platform..."
      args = ['platform', 'add', platform]
      spawn @cordova, args, cwd: path.join(@parent_root, @out)
        .progress (process) =>
          process.stdout.on 'data', (data) => @d.notify(data.toString().trim())
          process.stderr.on 'data', (data) => console.error(data.toString().trim())

###*
 * [build_platforms description]
 * @return {[type]} [description]
###
build_platforms = ->
  args = ['build']
  spawn @cordova, args, cwd: path.join(@parent_root, @out)
    .progress (process) =>
      process.stdout.on 'data', (data) => @d.notify(data.toString().trim())
      process.stderr.on 'data', (data) => console.error(data.toString().trim())
