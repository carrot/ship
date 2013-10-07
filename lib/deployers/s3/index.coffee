class S3

  constructor: (@path) ->

  deploy: (cb) ->
    console.log "deploying #{@path} to S3"
    cb()

module.exports = S3
