fs = require 'fs'
path = require 'path'
ArgumentParser = require('argparse').ArgumentParser
_ = require 'lodash'

packageInfo = require(path.join(__dirname, '../package.json'))
Deployer = require './deployer'
deployers = require './deployers'
ship = require './'

camel2dash = (string) ->
  string.replace /([A-Z])/g, (m) ->
    "-#{ m.toLowerCase() }"

jsonSchema2Argparse = (name, opt) ->
  argObject =
    dest: name
    type: opt.type
    required: not opt.default?
    help: opt.description ? ''

  if opt.default? then argObject.defaultValue = opt.default

  if argObject.type is 'integer'
    argObject.type = 'int'
  else if argObject.type is 'boolean'
    delete argObject.type
    if argObject.default is true
      argObject.action = 'storeFalse'
    else
      argObject.action = 'storeTrue'
  else if argObject.type is 'array'
    delete argObject.type
    argObject.action = 'append'

  return argObject

argparser = new ArgumentParser(
  version: packageInfo.version
  addHelp: true
  description: packageInfo.description
)

globalDeployerOpts = []
for name, opt of (new Deployer()).configSchema.schema
  argparser.addArgument(
    ["--#{camel2dash name}"]
    jsonSchema2Argparse name, opt
  )
  globalDeployerOpts.push name

deployerSubparsers = argparser.addSubparsers(
  title: 'deployer'
  dest: 'deployer'
)

for name, Deployer of deployers
  deployerParser = deployerSubparsers.addParser(
    name
    addHelp: true
  )
  for name, opt of (new Deployer()).configSchema.schema
    if name in globalDeployerOpts then continue
    deployerParser.addArgument(
      ["--#{camel2dash name}"]
      jsonSchema2Argparse name, opt
    )

argparser.addArgument(
  []
  dest: 'optsFile'
  type: 'string'
  defaultValue: './ship.opts'
  metavar: 'OPTS_FILE'
  nargs: '?'
  help: 'attempt to load extra args from a file'
)

###*
 * load opts from a file & return the array of opts
###
getOptsFile = (filename) ->
  return fs.readFileSync(filename, 'utf8').trim().split(/\s+/)

if process.argv.length is 2
  # ship was called with no args at all - add default shipfile
  process.argv.concat('./ship.opts')

# process optsfiles manually & inject into list of args where the optsfile is
for arg, i in process.argv
  if /^(?!--).*ship.*\.opts$/.test arg
    # it's an opts file
    process.argv[i] = getOptsFile(arg)
process.argv = _.flatten process.argv

args = argparser.parseArgs()

ship.deploy(args).done( ->
  console.log('done!')
)
