fs = require 'fs'
async = require 'async'
path = require 'path'
Transport = require '../transport'

class Fs extends Transport
  setup: (callback) ->
    @logger.debug 'Verifying path %s', @options.path
    async.waterfall [
      (callback) => fs.realpath @options.path, callback
      (@localPath, callback) => fs.stat @localPath, callback
      (stat, callback) =>
        if not stat.isDirectory()
          callback new Error "Invalid path: #{ @localPath }"
        else
          callback()
    ], (error) =>
      if error?.code is 'ENOENT'
        callback new Error "Invalid path: #{ @localPath or @options.path }"
      else
        callback error

  resolvePath: (filename) ->
    path.join @localPath, filename

  createReadStream: (filename) ->
    fs.createReadStream @resolvePath filename

  putFile: (filename, size, stream, callback) ->
    writeStream = fs.createWriteStream @resolvePath filename
    writeStream.on 'error', callback
    writeStream.on 'finish', callback
    stream.pipe writeStream

  deleteFile: (filename, callback) ->
    fs.unlink @resolvePath(filename), callback

  makeDirectory: (filename, callback) ->
    fs.mkdir @resolvePath(filename), callback

  deleteDirectory: (filename, callback) ->
    fs.rmdir @resolvePath(filename), callback

  listDirectory: (dirname, callback) ->
    dir = @resolvePath dirname
    async.waterfall [
      (callback) -> fs.readdir dir, callback
      (files, callback) ->
        async.map files, (file, callback) ->
          async.waterfall [
            (callback) -> fs.stat path.join(dir, file), callback
            (stat, callback) ->
              file += '/' if stat.isDirectory()
              callback null, file
          ], callback
        , callback
    ], callback

module.exports = Fs
