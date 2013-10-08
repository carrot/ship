class Dropbox

  constructor: (@path) ->

  configure: (c) -> @config = c

  deploy: (cb) ->
    console.log "deploying #{@path} to Dropbox"
    cb()

module.exports = Dropbox
