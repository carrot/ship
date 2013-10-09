fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

exports.create = (filepath) ->
  console.log "creating conf file"
  # fs.openSync(path.join(filepath, 'ship.conf'), 'w')

exports.update = (filepath, contents) ->
  file = path.join(filepath, 'ship.conf')
  console.log "updating conf file"
  console.log yaml.safeDump(contents)
  # fs.writeFileSync(file, yaml.safeDump(contents))
