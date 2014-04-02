fs = require 'fs'
path = require 'path'
packageInfo = require(path.join(__dirname, '../package.json'))
ArgumentParser = require('argparse').ArgumentParser

deployers = require './deployers'

argparser = new ArgumentParser(
  version: packageInfo.version
  addHelp: true
  description: packageInfo.description
)
argparser.addArgument(
  ['--deployer', '-d']
  choices: Object.keys(deployers)
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

###*
 * Ask for an array of config options.
 * @return {Array<string>} The array of answers.
###
_prompt = (options) ->
  console.log "please enter the following config details for #{@deployerName.bold}".green
  prompt("#{option}:") for option in options
