fs   = require 'fs'
path = require 'path'
_s   = require('underscore.string')

iterator = (acc, file) ->
  if file == 'index.coffee'
    acc
  else
    helper          = require(path.resolve(__dirname, file))
    helperName      = _s.camelize(file.replace('.coffee', ''))
    acc[helperName] = helper

    acc

module.exports = fs.readdirSync(__dirname).reduce(iterator, {})
