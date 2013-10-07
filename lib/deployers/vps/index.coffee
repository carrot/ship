class VPS

  constructor: (@path) ->

  deploy: (cb) ->
    console.log "deploying #{@path} to VPS"
    cb()

module.exports = VPS
