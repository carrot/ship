class Heroku

  constructor: (@path) ->

  deploy: (cb) ->
    console.log "deploying #{@path} to Heroku"
    cb()

module.exports = Heroku
