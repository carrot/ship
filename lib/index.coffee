class Ship
  constructor: (@adapter) ->

  deploy: ->
    @adapter.deploy()

module.exports = Ship
