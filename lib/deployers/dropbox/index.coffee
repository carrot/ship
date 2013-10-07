class Dropbox

  constructor: (@path) ->

  deploy: (cb) ->
    console.log "deploying #{@path} to Dropbox"
    cb()

module.exports = Dropbox
