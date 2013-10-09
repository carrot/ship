class Heroku

  constructor: (@path) ->
    @name = 'Heroku'
    @config =
      access_key: ''
      secret_key: ''

  deploy: (cb) ->
    console.log "deploying #{@path} to Heroku"
    cb()

module.exports = Heroku
