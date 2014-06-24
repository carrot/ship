stream = require 'stream'

# this absolute voodoo magic was adapted from
# https://github.com/flatiron/prompt/blob/master/test/helpers.js

class MockReadWriteStream extends stream.Stream

  constructor: ->
    @on 'pipe', (src) ->
      _emit = src.emit
      src.emit = -> _emit.apply(src, arguments)
      src.on 'data', (d) => @emit('data', d + '')

    for method in ['resume', 'pause', 'setEncoding', 'flush', 'end']
      MockReadWriteStream.prototype[method] = ->

  write: (msg) ->
    @emit('data', msg)
    true

  writeNextTick: (msg) ->
    process.nextTick => @write(msg)

exports.stdin = new MockReadWriteStream()
