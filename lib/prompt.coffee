require 'colors'
inquirer = require 'inquirer'
W        = require 'when'

###*
 * A light wrapper for the prompt interface, which uses inquirer to gather info
 * from the user via command line. The use of deferred and the progress event
 * are mainly for testing. You get access the the readline object from the
 * prompt once it has started up, so this can be grabbed from the progress event
 * and written to in order to use automated tests.
 *
 * @param  {String} name - name of the deployer being used
 * @param  {Array} required - required config params to ask for
 * @return {Promise} promise containing user-entered details
###

module.exports = (name, required) ->
  console.log "Please enter the following config details for #{name.bold}".green
  console.log "Need help? see https://github.com/carrot/ship".grey

  deferred = W.defer()

  questions = required.map((v) -> { name: v, message: v } )
  prompt = inquirer.prompt(questions, deferred.resolve)

  deferred.notify(prompt)

  return deferred.promise
