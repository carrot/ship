W = require 'when'

module.exports = -> W.resolve()

module.exports.config =
  required: ['nothing']
