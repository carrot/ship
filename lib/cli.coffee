fs = require 'fs'
path = require 'path'
promptSync = require 'sync-prompt'
packageInfo = require(path.join(__dirname, '../package.json'))
ArgumentParser = require('argparse').ArgumentParser

deployers = require './deployers'
ShipFile = require './shipfile'
Ship = require './'

###*
 * Ask for an array of config options.
 * @param {[type]} deployer [description]
 * @param {String[]} questions [description]
 * @return {Object<string>} The config object of answers.
###
prompt = (deployer, questions) ->
  console.log "please enter the following config details for #{deployer.bold}".green
  answers = {}
  for question in questions
    answers[question] = promptSync("#{question}:")
  answers

argparser = new ArgumentParser(
  version: packageInfo.version
  addHelp: true
  description: packageInfo.description
)
argparser.addArgument(
  ['--deployer', '-d']
  choices: Object.keys(deployers)
  required: true # remove when https://github.com/carrot/ship/issues/25 closes
  type: 'string'
  help: 'The deployer to use. Selects the first deployer in the config file by default.'
)
argparser.addArgument(
  ['--path', '-p']
  type: 'string'
  defaultValue: './'
  help: 'The path to the root of the project to be shipped. Set to ./ if no path is specified'
)
argparser.addArgument(
  ['--config', '-c']
  type: 'string'
  defaultValue: './ship.json'
  help: 'The path to the config file. Set to ./ship.json if no path is specified'
)
args = argparser.parseArgs()

shipFile = new ShipFile(args.config)
shipFile
  .loadFile()
  .then( ->
    shipFile.setDeployerConfig(
      args.deployer
      prompt(args.deployer, shipFile.getMissingConfigValues(args.deployer))
    )
  ).then( ->
    shipFile.updateFile()
  ).then( ->
    ship = new Ship(shipFile, args.path)
    ship.deploy(args.deployer)
  ).then(
    () ->
      console.log('deploy done!')
    (err) ->
      console.error("oh no!: #{err}")
  )
