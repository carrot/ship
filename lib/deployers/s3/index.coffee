class S3

  constructor: (@path) ->
    @name = 'Amazon S3'
    @config =
      access_key: ''
      secret_key: ''

  deploy: (cb) ->
    console.log "deploying #{@path} to S3"
    cb()

module.exports = S3
