W       = require 'when'
node    = require 'when/node'
fs      = require 'fs-extra'
path    = require 'path'
{spawn} = require 'child-process-promise'

module.exports = (root, config) ->

  d = W.defer()

  # we want to be one level above the project root
  parent_root = path.resolve(root, '..')

  # path to the cordova node binary
  cordova = path.resolve(
    __dirname,
    '../../../node_modules/cordova/bin/cordova'
  )

  # throw a warning for each missing configuration
  ['package_name', 'name', 'platforms'].forEach (prop) ->
    switch prop
      when 'package_name' then msg = "com.company.project"
      when 'name' then msg = "ProjectName"
      when 'platforms' then msg = "ios android"
    if not config[prop] then d.reject "#{prop} not specified - example: #{msg}"

  # add some data to the context to make it available later
  # on in the promise chain sequence
  data =
    d               : d # a reference to the deferred object
    config          : config # the deployer config
    platforms       : config.platforms.split(' ') # array of platforms
    build_type      : config.build_type or 'release'
    build_app       : config.build_app or true # `cordova build`?
    root            : root # root path
    parent_root     : parent_root # parent dir of root path
    project_exists  : null # project existence flag
    platform_exists : {} # platform existence flags
    out             : config.out_dir or 'cordova' # out directory
    cordova         : cordova # path to cordova node binary

  W().with(data)
    .then check_project_existence
    .then create_or_update_project
    .then check_platform_existence
    .then add_platforms
    .then build_platforms
    .done ->
      d.resolve
        deployer: 'cordova'
        destroy: destroy.bind(data)
    , d.reject

  return d.promise

module.exports.config =
  required: ['package_name', 'name', 'platforms']
  optional: ['build_type', 'out_dir', 'build_app']

###*
 * checks for `root/../cordova/config.xml` to determine if the project
 * already exists and makes this available to other methods
 * as a flag on the context
 * @return {Promise} - the config.xml
###
check_project_existence =  ->
  @d.notify "Checking for existing Cordova project..."
  node.call(fs.readFile, path.join(@out, 'config.xml'))
    .then  => @project_exists = true; @d.notify "Cordova project found"
    .catch => @project_exists = false; @d.notify "Existing project not found"

###*
 * uses the flag from `check_project_existence` to determine whether
 * the project needs to be created, or just updated
 * @return {Promise} - the created or updated project
###
create_or_update_project = ->
  if @project_exists then update_project.call(@) else create_project.call(@)

###*
 * creates a cordova project and copies the `root` folder to `cordova/www`
 * @return {[Promise} - the created project
###
create_project = ->
  args = ['create', @out, @config.package_name, @config.name]
  spawn_cordova.call @, args, @parent_root
    .then copy_files.bind(@)
    .then => @d.notify "Done creating new Cordova project"

###*
 * updates a project by copying the `root` folder to `cordova/www`
 * @return {Promise} the copied files
###
update_project = ->
  copy_files.call(@)

###*
 * copies `root` to `cordova/www`
 * @return {Promise} - the copied files
###
copy_files = ->
  @d.notify "Copying files..."
  www_dir = path.join(@parent_root, @out, 'www')
  remove_dir(www_dir)
    .then copy_dir.bind(@, @root, www_dir)

###*
 * removes a directory
 * @param  {String} dir - path to the directory
 * @return {Promise} - that the directory was removed
###
remove_dir = (dir) ->
  node.call fs.remove, dir

###*
 * copies a directory
 * @param  {String} src - path to the source directory
 * @param  {String} dest - path to the destination directory
 * @return {Promise} - the moved directory
###
copy_dir = (src, dest) ->
  node.call fs.copy, src, dest, clobber: true

###*
 * checks if each platform exists by inspecting the platform folder
 * inside `cordova/platforms`
 * @return {Promise} - for the existence of each platform
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
 * runs `cordova platform add <platform>` for each platform
 * @return {Promise} - for all the added platforms
###
add_platforms = ->
  W.map @platforms, (platform) =>
    if not @platform_exists[platform]
      @d.notify "Adding #{platform} platform..."
      args = ['platform', 'add', platform]
      spawn_cordova.call @, args, path.join(@parent_root, @out)

###*
 * runs `cordova build`
 * @return {Promise} - for the built cordova packages
###
build_platforms = ->
  args = ['build', "--#{@build_type}"]
  spawn_cordova.call @, args, path.join(@parent_root, @out) if @build_app

###*
 * util function for spawning cordova and having it notify of progress
 * @param  {Array} args - command line flags to pass to cordova
 * @param  {String} cwd - the directory context that cordova must run in
 * @return {Promise} - for the executed command
###
spawn_cordova = (args, cwd) ->
  spawn @cordova, args, cwd: cwd
    .progress (process) =>
      process.stdout.on 'data', (data) => @d.notify(data.toString().trim())
      process.stderr.on 'data', (data) => console.error(data.toString().trim())

###*
 * destroys the built `cordova` directory
 * @return {Promise} for the destroyed `cordova` directory
###
destroy = ->
  node.call fs.remove, path.join(@parent_root, @out)
