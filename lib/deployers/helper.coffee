fs = require 'fs'
require 'shelljs/global'

###*
 * Includes some helper functions that are used in multiple deployers
###

checkGitRepo = ->
  if not which('git')
    throw new Error('You must install git - see http://git-scm.com')
  if not fs.existsSync('.git')
    throw new Error('Git must be initialized. Try `git init`.')
  if /fatal/.test(execute('git rev-list HEAD --count'))
    throw new Error('You need to make at least 1 commit before deploying')

  cmd = "git diff --quiet"
  unless exec(cmd).code is 0 and exec(cmd + ' --cached').code is 0
    throw new Error('You have uncommitted changes - please commit')

###*
 * @param {String} input The command to execute
 * @return {String|Boolean} `false` if there was a non-zero exit code, or the
   output of the command in a string if it succeeded
###
execute = (input, silent = true) ->
  cmd = exec(input, silent: silent)
  if cmd.code > 0 or cmd.output is '' then false else cmd.output.trim()

module.exports = {checkGitRepo, execute}
