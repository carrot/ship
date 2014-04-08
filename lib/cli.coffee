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
    loop
      answer = promptSync("#{question}:")
      check = deployers[deployer].config.validateOption(question, answer)
      if check.valid
        answers[question] = answer
        break
      else
        console.log error for error in check.errors
  answers

argparser = new ArgumentParser(
  version: packageInfo.version
  addHelp: true
  description: packageInfo.description
)
argparser.addArgument(
  ['--deployer', '-d']
  choices: Object.keys(deployers)
  type: 'string'
  help: 'The deployer to use. If this isn\'t specified then `defaultDeployer` from the config will be used.'
)
argparser.addArgument(
  ['--path', '-p']
  type: 'string'
  defaultValue: './'
  help: 'The path to the root of the project to be shipped. Defaults to ./ if no path is specified'
)
argparser.addArgument(
  ['--config', '-c']
  type: 'string'
  defaultValue: './ship.json'
  help: 'The path to the config file. Defaults to ./ship.json if no path is specified'
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
