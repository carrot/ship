fs = require 'fs'
path = require 'path'
promptSync = require('sync-prompt').prompt
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
  configObject = (new deployers[deployer]).config
  answers = {}
  for question in questions
    loop
      answer = promptSync("#{question}:")
      check = configObject.validateOption(question, answer)
      if check.valid
        answers[question] = answer
        break
      else
        console.log error for error in check.errors
  answers

promptBoolean = ->
  loop
    answer = promptSync('y/n:')
    if answer is 'y'
      return true
    else if answer is 'n'
      return false
    else
      console.error 'please enter "y" (for "yes") or "n" (for "no")'

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
  .catch((e) ->
    if e.code isnt 'ENOENT' then throw e
    console.error "#{args.config} was not found, would you like to create it?"
    if promptBoolean()
      return shipFile.updateFile()
    else
      throw new Error('aborted')
  ).then( ->
    shipFile.setDeployerConfig(
      args.deployer
      prompt(args.deployer, shipFile.getMissingConfigValues(args.deployer))
    )
  ).then( ->
    shipFile.updateFile()
  ).then( ->
    ship = new Ship(shipFile, args.path)
    ship.deploy(args.deployer)
  ).then( ->
    console.log('done!')
  ).catch((e) ->
    console.error "oh no!: #{e}"
    console.error e.stack
  )
