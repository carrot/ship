fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

exports.create = (filepath) ->
  if process.env.NODE_ENV == 'test'
    console.log 'creating shipfile'
  else
    fs.openSync(path.join(filepath, 'ship.conf'), 'w')

exports.update = (filepath, contents) ->
  file = path.join(filepath, 'ship.conf')
  
  if process.env.NODE_ENV == 'test'
    console.log 'updating shipfile'
    console.log yaml.safeDump(contents)
  else
    fs.writeFileSync(file, yaml.safeDump(contents))
