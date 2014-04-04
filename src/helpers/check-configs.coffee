path       = require 'path'
getConfig = require path.resolve(__dirname, 'get-config')

module.exports = ->
  if Object.keys(getConfig()).length == 0
    throw new Error("No hubot configuration in place. Please define the configuration as per the documentation of the hubot-pull-request plugin.")
