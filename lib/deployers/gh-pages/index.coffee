class Github

  constructor: (@path) ->

  deploy: (cb) ->
    console.log "deploying #{@path} to Github Pages"
    cb()

module.exports = Github
