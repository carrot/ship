class FTP

  constructor: (@path) ->

  deploy: (cb) ->
    console.log "deploying #{@path} to FTP"
    cb()

module.exports = FTP
