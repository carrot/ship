require 'coffee-script'

crypto = require 'crypto'
fs = require 'fs'
yaml = require 'js-yaml'


class md5sum

  constructor: (cargo, config) ->
    @cargo = cargo
    @config = config

    console.log @cargo
    # create array of files from cargo to hash


  run: (cb) ->
    @cargo = ignore_contents(@cargo)

    while content in @cargo[content]
      yaml.safeDump
        file: create_hash(content).call

    # update cargo to hold only updated cargo(update includes new files)
    @cargo = compare_hashes @config
    return @cargo



  ###*
   * @access private
  ###

  create_hash: (file) ->
    md5sum = crypto.createHash 'md5'

    rs = fs.readStream file

    rs.on('data', (data) ->
      md5sum.update data
    )

    rs.on('end', () ->
      data = md5sum.digest 'hex'
      return data
    )

  complete_hash: (cargo) ->
    cargoStuc(cargo, ->
      console.log 'complete_hash: cargoStuc complete'
      )

  compare_hashes: (config) ->
    # compare new hashes to previous
    # return updated(new) files
    console.log config


  ignore_contents: (ignore_path) ->
    console.log 'ignoring contents: ' + @ignores_path
    # return array of files to ignore
    while ignore in yaml.safeLoad fs.fileReadSync ignore_path, 'utf8'
      @ignores.push ignore


  cargoStuc = (dir, done) ->
    results = []
    fs.readdir dir, (err, list) ->
      return done(err) if err
      i = 0
      (next = ->
        file = list[i++]
        return done(null, results) unless file
        
        file = dir + "/" + file
        fs.stat file, (err, stat) ->
          if stat and stat.isDirectory()
            cargoStuc file, (err, res) ->
              results = results.concat(res)
              next()

          else
            results.push file
            next()

      )()


module.exports = md5sum
