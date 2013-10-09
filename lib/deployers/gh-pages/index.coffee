class Github

  constructor: (@path) ->
    @name = 'Github Pages'
    @config =
      access_key: ''
      secret_key: ''

  deploy: (cb) ->
    console.log "deploying #{@path} to Github Pages"
    cb()

module.exports = Github
