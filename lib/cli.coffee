fs = require 'fs'
path = require 'path'
ArgumentParser = require('argparse').ArgumentParser

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

argparser.addArgument(
  ['--config', '-c']
  type: 'string'
  defaultValue: './ship.opts'
  help: 'The path to the config file. Defaults to ./ship.opts if no path is specified'
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

args = argparser.parseArgs()
try
  opts = fs.readFileSync(args.optsFile, 'utf8').trim().split(/\s+/)
  process.argv = process.argv
    .slice(0, 2)
    .concat(opts.concat(process.argv.slice(2)))
  console.log process.argv
  args = argparser.parseArgs()

ship.deploy(args).then( ->
  console.log('done!')
).catch((e) ->
  console.error "oh no!: #{e}"
  console.error e.stack
)
