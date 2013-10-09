class FTP

  constructor: (@path) ->
    @name = 'FTP'
    @config =
      access_key: ''
      secret_key: ''

  deploy: (cb) ->
    console.log "deploying #{@path} to FTP"
    cb()

module.exports = FTP
