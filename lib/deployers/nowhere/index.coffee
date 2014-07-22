W = require 'when'

module.exports = -> W.resolve(deployer: 'nowhere')

module.exports.config =
  required: ['nothing']
