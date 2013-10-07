class Nodejitsu

  constructor: (@path) ->

  deploy: (cb) ->
    console.log "deploying #{@path} to Nodejitsu"
    cb()

module.exports = Nodejitsu
